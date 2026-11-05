import Supabase
import SwiftUI

enum AuthMode: Hashable {
  case signin, signup
}

/// Mirrors src/routes/auth.tsx (email sign in and sign up, plus Google and Apple).
struct AuthView: View {
  @State private var mode: AuthMode

  init(initialMode: AuthMode) {
    _mode = State(initialValue: initialMode)
  }

  var body: some View {
    VStack(spacing: 0) {
      Text("Patient area")
        .displayCaps(30)
        .multilineTextAlignment(.center)
        .accessibilityAddTraits(.isHeader)
      Text("Create an account with your contact details to request appointments.")
        .mutedText(14)
        .multilineTextAlignment(.center)
        .padding(.top, 12)

      Picker("Account", selection: $mode) {
        Text("SIGN IN").tag(AuthMode.signin)
        Text("SIGN UP").tag(AuthMode.signup)
      }
      .pickerStyle(.segmented)
      .padding(.top, 40)

      Group {
        switch mode {
        case .signin: SignInForm()
        case .signup: SignUpForm()
        }
      }
      .padding(.top, 32)

      SocialSignInButtons().padding(.top, 32)

      PolicyLinks().padding(.top, 48)
    }
    .foregroundStyle(Palette.foreground)
    .padding(.horizontal, 20)
    .padding(.vertical, 56)
    .frame(maxWidth: 480)
    .frame(maxWidth: .infinity)
  }
}

private struct SignInForm: View {
  @Environment(Toaster.self) private var toaster
  @State private var email = ""
  @State private var password = ""
  @State private var busy = false
  @State private var showingReset = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 8) {
        FieldLabel("Email")
        TextField("", text: $email)
          .textContentType(.emailAddress)
          .keyboardType(.emailAddress)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .clinicField()
          .accessibilityLabel("Email")
      }
      VStack(alignment: .leading, spacing: 8) {
        FieldLabel("Password")
        SecureField("", text: $password)
          .textContentType(.password)
          .clinicField()
          .accessibilityLabel("Password")
          .onSubmit(submit)
      }
      Button(busy ? "Signing in…" : "Sign in", action: submit)
        .buttonStyle(.clinic(.primary, fullWidth: true))
        .disabled(busy || email.isEmpty || password.isEmpty)

      Button("Forgot your password?") { showingReset = true }
        .font(AppFont.bodyRegular(14))
        .underline()
        .foregroundStyle(Palette.mutedForeground)
        .frame(maxWidth: .infinity)
    }
    .sheet(isPresented: $showingReset) {
      ForgotPasswordSheet(email: email)
    }
  }

  private func submit() {
    guard !busy, !email.isEmpty, !password.isEmpty else { return }
    busy = true
    Task {
      do {
        try await supabase.auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        toaster.success("Welcome back.")
      } catch {
        toaster.error(error)
      }
      busy = false
    }
  }
}

private struct SignUpForm: View {
  @Environment(Toaster.self) private var toaster
  @State private var fullName = ""
  @State private var phone = ""
  @State private var email = ""
  @State private var password = ""
  @State private var busy = false
  @State private var sent = false

  private var canSubmit: Bool {
    !busy && !fullName.isEmpty && !phone.isEmpty && !email.isEmpty && !password.isEmpty
  }

  var body: some View {
    if sent {
      VStack(alignment: .leading, spacing: 24) {
        (Text("We've sent a confirmation link to ")
          + Text(email).foregroundColor(Palette.foreground).font(AppFont.bodyRegular(14))
          + Text(". Click it to activate your account, then sign in to request an appointment."))
          .mutedText(14)
          .frame(maxWidth: .infinity, alignment: .leading)
        ResendVerification(email: email)
      }
    } else {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Full name")
          TextField("", text: $fullName)
            .textContentType(.name)
            .clinicField()
            .accessibilityLabel("Full name")
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Contact number")
          TextField("", text: $phone)
            .textContentType(.telephoneNumber)
            .keyboardType(.phonePad)
            .clinicField()
            .accessibilityLabel("Contact number")
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Email")
          TextField("", text: $email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .clinicField()
            .accessibilityLabel("Email")
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Password")
          SecureField("", text: $password)
            .textContentType(.newPassword)
            .clinicField()
            .accessibilityLabel("Password, at least 8 characters")
        }
        Button(busy ? "Creating account…" : "Create account", action: submit)
          .buttonStyle(.clinic(.primary, fullWidth: true))
          .disabled(!canSubmit)

        Divider().overlay(Palette.border).padding(.top, 12)
        ResendVerification(email: "")
      }
    }
  }

  private func submit() {
    guard canSubmit else { return }
    guard password.count >= 8 else {
      toaster.error("Please use a password of at least 8 characters.")
      return
    }
    busy = true
    Task {
      do {
        let response = try await supabase.auth.signUp(
          email: email.trimmingCharacters(in: .whitespaces),
          password: password,
          data: ["full_name": .string(fullName), "phone": .string(phone)],
          redirectTo: SupabaseConfig.emailConfirmedRedirect
        )
        if case .session = response {
          toaster.success("Account created.")
        } else {
          sent = true
          toaster.success("Almost there — check your email to confirm your account.")
        }
      } catch {
        toaster.error(error)
      }
      busy = false
    }
  }
}

/// Sends the sign-up confirmation email again, for people whose first one
/// never arrived or expired.
private struct ResendVerification: View {
  @Environment(Toaster.self) private var toaster
  @State private var email: String
  @State private var busy = false

  init(email: String) {
    _email = State(initialValue: email)
  }

  private var trimmed: String { email.trimmingCharacters(in: .whitespaces) }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      FieldLabel("Didn't get your verification email?")
      TextField("Your email address", text: $email)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .clinicField()
        .accessibilityLabel("Email for verification")
        .onSubmit(resend)
      Button(busy ? "Sending…" : "Resend verification email", action: resend)
        .buttonStyle(.clinic(.outline, fullWidth: true))
        .disabled(busy || trimmed.isEmpty)
    }
  }

  private func resend() {
    guard !busy, !trimmed.isEmpty else { return }
    busy = true
    Task {
      do {
        try await supabase.auth.resend(
          email: trimmed, type: .signup, emailRedirectTo: SupabaseConfig.emailConfirmedRedirect)
        toaster.success("Verification email sent. Please check your inbox and spam folder.")
      } catch {
        toaster.error(error)
      }
      busy = false
    }
  }
}

/// Emails a reset link. Opening it on this iPhone brings the person back into
/// the app, signed in, and NewPasswordSheet asks for the new password.
private struct ForgotPasswordSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Toaster.self) private var toaster
  @State private var email: String
  @State private var busy = false
  @State private var sent = false

  init(email: String) {
    _email = State(initialValue: email)
  }

  private var trimmed: String { email.trimmingCharacters(in: .whitespaces) }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        if sent {
          (Text("If there's an account for ")
            + Text(trimmed).foregroundColor(Palette.foreground).font(AppFont.bodyRegular(14))
            + Text(", we've sent it a link to choose a new password. Open the link on this iPhone and the app will ask for your new password."))
            .mutedText(14)
          Button("Done") { dismiss() }
            .buttonStyle(.clinic(.primary, fullWidth: true))
        } else {
          Text("Enter your email and we'll send you a link to choose a new password.")
            .mutedText(14)
          VStack(alignment: .leading, spacing: 8) {
            FieldLabel("Email")
            TextField("", text: $email)
              .textContentType(.emailAddress)
              .keyboardType(.emailAddress)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .clinicField()
              .accessibilityLabel("Email")
              .onSubmit(send)
          }
          Button(busy ? "Sending…" : "Email me a reset link", action: send)
            .buttonStyle(.clinic(.primary, fullWidth: true))
            .disabled(busy || trimmed.isEmpty)
        }
        Spacer()
      }
      .padding(20)
      .foregroundStyle(Palette.foreground)
      .background(Palette.background)
      .navigationTitle("Reset password")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
  }

  private func send() {
    guard !busy, !trimmed.isEmpty else { return }
    busy = true
    Task {
      do {
        try await supabase.auth.resetPasswordForEmail(
          trimmed,
          redirectTo: SupabaseConfig.passwordResetRedirect
        )
        sent = true
      } catch {
        toaster.error(error)
      }
      busy = false
    }
  }
}

/// Shown after a reset-password link opens the app.
struct NewPasswordSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Toaster.self) private var toaster
  @State private var password = ""
  @State private var confirm = ""
  @State private var busy = false

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        Text("Choose a new password for your account.")
          .mutedText(14)
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("New password")
          SecureField("", text: $password)
            .textContentType(.newPassword)
            .clinicField()
            .accessibilityLabel("New password, at least 8 characters")
        }
        VStack(alignment: .leading, spacing: 8) {
          FieldLabel("Confirm new password")
          SecureField("", text: $confirm)
            .textContentType(.newPassword)
            .clinicField()
            .accessibilityLabel("Confirm new password")
            .onSubmit(save)
        }
        Button(busy ? "Saving…" : "Save new password", action: save)
          .buttonStyle(.clinic(.primary, fullWidth: true))
          .disabled(busy || password.isEmpty || confirm.isEmpty)
        Spacer()
      }
      .padding(20)
      .foregroundStyle(Palette.foreground)
      .background(Palette.background)
      .navigationTitle("New password")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Later") { dismiss() }
        }
      }
    }
    .interactiveDismissDisabled(busy)
  }

  private func save() {
    guard !busy else { return }
    guard password.count >= 8 else {
      toaster.error("Please use a password of at least 8 characters.")
      return
    }
    guard password == confirm else {
      toaster.error("The two passwords don't match.")
      return
    }
    busy = true
    Task {
      do {
        try await supabase.auth.update(user: UserAttributes(password: password))
        toaster.success("Password updated.")
        dismiss()
      } catch {
        toaster.error(error)
      }
      busy = false
    }
  }
}
