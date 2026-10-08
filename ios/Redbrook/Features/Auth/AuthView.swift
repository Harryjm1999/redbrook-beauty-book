import Supabase
import SwiftUI

enum AuthMode: Hashable {
  case signin, signup
}

/// Mirrors src/routes/auth.tsx (email sign in and sign up).
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
      (Text("We've sent a confirmation link to ")
        + Text(email).foregroundColor(Palette.foreground).font(AppFont.bodyRegular(14))
        + Text(". Click it to activate your account, then sign in to request an appointment."))
        .mutedText(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
          data: ["full_name": .string(fullName), "phone": .string(phone)]
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
