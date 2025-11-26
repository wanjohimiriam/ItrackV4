// Auth Models for API requests and responses

class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    };
  }
}

class FirstLoginRequest {
  final String email;
  final String temporaryPassword;
  final String newPassword;
  final String confirmPassword;

  FirstLoginRequest({
    required this.email,
    required this.temporaryPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'temporaryPassword': temporaryPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

// Auth Response Models
class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? refreshToken;
  final bool? isFirstLogin;
  final Map<String, dynamic>? data;
  final String? expiration;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.refreshToken,
    this.isFirstLogin,
    this.data,
    this.expiration,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      refreshToken: json['refreshToken'],
      isFirstLogin: json['isFirstLogin'],
      data: json['data'],
      expiration: json['expiration'],
    );
  }
}

class User {
  final String? id;
  final String? email;
  final String? name;
  final String? role;

  User({
    this.id,
    this.email,
    this.name,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}