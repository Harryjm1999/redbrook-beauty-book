-- profiles
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT,
  phone TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- roles
CREATE TYPE public.app_role AS ENUM ('admin', 'staff', 'patient');
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role public.app_role)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role);
$$;

CREATE OR REPLACE FUNCTION public.is_staff(_user_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('admin','staff'));
$$;

CREATE POLICY "Users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Staff read all roles" ON public.user_roles FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

CREATE POLICY "Users read own profile" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "Staff read all profiles" ON public.profiles FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "Users insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- treatments
CREATE TABLE public.treatments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER NOT NULL DEFAULT 60,
  price_from NUMERIC(10,2),
  price_note TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT ON public.treatments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.treatments TO authenticated;
GRANT ALL ON public.treatments TO service_role;
ALTER TABLE public.treatments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view treatments" ON public.treatments FOR SELECT USING (true);
CREATE POLICY "Staff manage treatments" ON public.treatments FOR ALL TO authenticated
  USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));

-- bookings
CREATE TABLE public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  treatment_id UUID REFERENCES public.treatments(id) ON DELETE SET NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  patient_notes TEXT,
  staff_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT bookings_status_check CHECK (status IN ('pending','confirmed','declined','cancelled'))
);
CREATE INDEX bookings_starts_at_idx ON public.bookings (starts_at);
GRANT SELECT, INSERT, UPDATE ON public.bookings TO authenticated;
GRANT ALL ON public.bookings TO service_role;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Patients read own bookings" ON public.bookings FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Staff read all bookings" ON public.bookings FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "Patients create own bookings" ON public.bookings FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id AND status = 'pending');
CREATE POLICY "Patients update own bookings" ON public.bookings FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Staff update all bookings" ON public.bookings FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));

-- updated_at helper
CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER treatments_updated_at BEFORE UPDATE ON public.treatments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', ''),
    NEW.email,
    NEW.raw_user_meta_data ->> 'phone'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END; $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- busy ranges for availability (no patient details exposed)
CREATE OR REPLACE FUNCTION public.busy_ranges(_day DATE)
RETURNS TABLE (starts_at TIMESTAMPTZ, ends_at TIMESTAMPTZ)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT b.starts_at, b.ends_at FROM public.bookings b
  WHERE b.status IN ('pending','confirmed')
    AND b.starts_at >= _day::timestamptz
    AND b.starts_at < (_day + 1)::timestamptz;
$$;
REVOKE ALL ON FUNCTION public.busy_ranges(DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.busy_ranges(DATE) TO authenticated;

-- seed treatments
INSERT INTO public.treatments (name, category, description, duration_minutes, price_from, price_note, sort_order) VALUES
('Complimentary Consultation','Consultations','A no-obligation consultation to discuss your needs and design an individual treatment plan.',30,0,'Free',1),
('CO2 Laser Skin Resurfacing - Scar Reduction','Advanced Skin Care','3D Vjuve fractional CO2 laser for scarring. Course of 4 treatments.',60,400,'£400 course of 4',10),
('CO2 Laser Skin Resurfacing - Full Face','Advanced Skin Care','Fractional CO2 laser resurfacing for the full face. Course of 4 treatments.',75,1000,'£1000 course of 4',11),
('CO2 Laser Resurfacing - Face, Neck & Chest','Advanced Skin Care','Fractional CO2 laser for face, neck and chest. Course of 4 treatments.',90,1400,'£1400 course of 4',12),
('Skin Rejuvenation - Single Treatment','Advanced Skin Care','Tailored facial including laser rejuvenation, peels, microdermabrasion, micro needling or carbon facial.',60,95,'From £95',13),
('Skin Rejuvenation - Course of 4','Advanced Skin Care','Course of four tailored rejuvenation treatments.',60,300,'£300 course of 4',14),
('Skin Rejuvenation - Course of 6','Advanced Skin Care','Course of six tailored rejuvenation treatments.',60,500,'£500 course of 6',15),
('3D Dermaforce Micro-needling & RF','Advanced Skin Care','Micro-needling combined with radio frequency for skin tightening. Single treatment.',60,600,'£600 single, £1500 course of 3',16),
('Mesotherapy','Advanced Skin Care','Hyaluronic acid and nutrient infusion for a natural anti-ageing boost.',45,150,'£150 single, £400 course of 4',17),
('Plasma Needling - Upper or Lower Eyelids','Plasma Needling','Non-surgical eyelid correction using plasma technology.',60,200,'£200 per treatment, 3 for £500',20),
('Plasma Needling - Upper & Lower Eyelids','Plasma Needling','Non-surgical blepharoplasty for both upper and lower eyelids.',75,300,'£300 per treatment, 3 for £700',21),
('Wrinkle Relaxing - 1 Area','Anti Aging','Wrinkle relaxing injections for one area such as frown lines, crow''s feet or forehead.',30,150,'£150',30),
('Wrinkle Relaxing - 2 Areas','Anti Aging','Wrinkle relaxing injections for two areas.',30,200,'£200',31),
('Wrinkle Relaxing - 3 Areas','Anti Aging','Wrinkle relaxing injections for three areas.',40,240,'£240',32),
('Wrinkle Relaxing - 4+ Areas','Anti Aging','Advanced wrinkle relaxing including bunny lines, gummy smile, smokers'' lines and jaw tightening.',45,260,'From £260',33),
('Hyperhidrosis - Underarms','Anti Aging','Treatment to reduce underarm sweating, completed in two treatments 4 weeks apart.',30,400,'£400 for the course',34),
('Dermal Filler - 1ml','Anti Aging','Gold standard dermal filler, supplied in 1ml.',45,160,'£160 per ml',35),
('Dermal Filler - 2ml or more','Anti Aging','Dermal filler treatment using 2ml or more.',60,300,'From £300',36),
('Skin Boosters (Profhilo, Sunekos, Sculptra, Seventy Hyal)','Anti Aging','Injectable hydration and firmness boosters, discussed at consultation.',45,200,'From £200',37),
('PDO Thread Lip Lift','PDO Threads','Rejuvenates and lifts the lips using polydioxanone threads.',60,400,'£400',40),
('PDO Thread Brow Lift','PDO Threads','Lifts the brows and reduces heaviness of the eyelids.',60,500,'£500',41),
('PDO Under Chin Thread Lift','PDO Threads','Lifts the under chin area by stimulating collagen production.',60,500,'£500',42),
('PDO Nasolabial Thread Lift','PDO Threads','Thread lift for smile lines and nasolabial folds.',60,500,'£500',43),
('PDO Thread Neck Lift','PDO Threads','Thread lift for horizontal neck lines and skin firmness.',75,550,'£550',44),
('Lipo Ultimate Pro - Single Area Cryo','Body Image','Cryo fat freezing for one area such as inner thigh, hips or love handles.',75,250,'£250 single treatment',50),
('Lipo Ultimate Pro - Tummy Course','Body Image','Skin tightening, inch loss and cellulite course of 8 treatments.',60,1000,'£1000 course of 8',51),
('Lipo Ultimate Pro - Thighs Course','Body Image','Course of 8 body contouring treatments for the thighs.',60,1000,'£1000 course of 8',52),
('Lipo Ultimate Pro - Arms Course','Body Image','Course of 8 body contouring treatments for the arms.',60,800,'£800 course of 8',53),
('Lipo Ultimate Pro - Bum Lift Course','Body Image','Course of 8 lifting and tightening treatments.',60,800,'£800 course of 8',54),
('Aqualyx Fat Dissolving','Body Image','Non-surgical fat dissolving injections for face or body.',45,250,'£250 per treatment',55),
('Weight Loss Injection (Saxenda)','Well Being','Prescription weight loss injection programme, including needles.',30,75,'From £75',56),
('Laser Hair Removal - Lip','Body Image','Permanent hair reduction course for the lip.',20,200,'£200 course',60),
('Laser Hair Removal - Lip & Chin','Body Image','Permanent hair reduction course for lip and chin.',30,300,'£300 course',61),
('Laser Hair Removal - Underarm','Body Image','Permanent hair reduction course for underarms.',30,300,'£300 course',62),
('Laser Hair Removal - Bikini','Body Image','Permanent hair reduction course for the bikini area.',30,300,'£300 course',63),
('Laser Hair Removal - Half Leg','Body Image','Permanent hair reduction course for half leg.',45,400,'£400 course',64),
('Laser Hair Removal - Full Leg','Body Image','Permanent hair reduction course for full legs.',60,600,'£600 course',65),
('Laser Hair Removal - Chest or Back','Body Image','Permanent hair reduction course for chest or back.',45,500,'£500 course',66),
('Semi-Permanent Make Up - Eyebrows','Body Image','Semi-permanent brows, completed over two applications 4-6 weeks apart.',90,300,'£300',70),
('Semi-Permanent Make Up - Eyeliner','Body Image','Semi-permanent eyeliner, completed over two applications.',90,300,'£300',71),
('Semi-Permanent Make Up - Lip Liner','Body Image','Semi-permanent lip liner, completed over two applications.',90,300,'£300',72),
('Semi-Permanent Make Up - Full Lip Colour','Body Image','Semi-permanent full lip colour.',120,400,'£400',73),
('Semi-Permanent Make Up - Colour Touch Up','Body Image','Top up application to maintain semi-permanent make up.',60,100,'£100',74),
('Thread Vein Removal','Advanced Skin Care','Sclerotherapy for thread veins on face, legs or chest.',45,150,'From £150 per session',80),
('Tattoo Removal','Advanced Skin Care','Tattoo removal charged by size and colour of the tattoo.',45,300,'From £300',81),
('Mole & Skin Tag Removal','Advanced Skin Care','Removal of skin tags, blemishes and moles. Free consultation advised.',30,50,'From £50',82);