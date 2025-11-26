// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:itrack/http/controller/authcontroller.dart';

// class FirstLoginResetScreen extends StatefulWidget {
//   const FirstLoginResetScreen({super.key});

//   @override
//   State<FirstLoginResetScreen> createState() => _FirstLoginResetScreenState();
// }

// class _FirstLoginResetScreenState extends State<FirstLoginResetScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _tempPasswordController = TextEditingController();
//   final _newPasswordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
  
//   bool _obscureTempPassword = true;
//   bool _obscureNewPassword = true;
//   bool _obscureConfirmPassword = true;

//   late final AuthController authController;

//   @override
//   void initState() {
//     super.initState();
//     authController = Get.find<AuthController>();
    
//     // Pre-fill email if available
//     if (authController.tempEmail.isNotEmpty) {
//       _emailController.text = authController.tempEmail;
//     }

//     // Listen to auth state changes
//     ever(authController.authState.obs, (AuthState state) {
//       if (state == AuthState.authenticated) {
//         Get.offAllNamed('/home');
//       } else if (state == AuthState.unauthenticated) {
//         Get.offAllNamed('/login');
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _tempPasswordController.dispose();
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _handlePasswordReset() async {
//     if (_formKey.currentState!.validate()) {
//       FocusScope.of(context).unfocus();
      
//       await authController.firstTimeLoginReset(
//         // email: _emailController.text.trim(),
//         // temporaryPassword: _tempPasswordController.text,
//         // newPassword: _newPasswordController.text,
//         // confirmPassword: _confirmPasswordController.text,
//       );
//     }
//   }

//   void _goBackToLogin() {
//     authController.navigateToLogin();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C2C2C)),
//           onPressed: _goBackToLogin,
//         ),
//         title: const Text(
//           'First Time Setup',
//           style: TextStyle(
//             color: Color(0xFF2C2C2C),
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header section
//                 const Center(
//                   child: Icon(
//                     Icons.security,
//                     size: 80,
//                     color: Color(0xFFD32F2F),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
                
//                 const Center(
//                   child: Text(
//                     'Reset Your Password',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF2C2C2C),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 const Center(
//                   child: Text(
//                     'For security, you need to create a new password before accessing your account.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Color(0xFF5C5C5C),
//                       height: 1.4,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 40),

//                 // Error message
//                 Obx(() {
//                   if (authController.errorMessage.isNotEmpty) {
//                     return Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(12),
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.red[50],
//                         border: Border.all(color: Colors.red[300]!),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.error_outline, color: Colors.red[700], size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               authController.errorMessage,
//                               style: TextStyle(color: Colors.red[700], fontSize: 14),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 }),

//                 // Email field
//                 const Text(
//                   'Email Address',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF2C2C2C),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildTextFormField(
//                   controller: _emailController,
//                   hintText: 'Enter your email address',
//                   prefixIcon: Icons.email_outlined,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value?.isEmpty ?? true) {
//                       return 'Email is required';
//                     }
//                     if (!GetUtils.isEmail(value!)) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),

//                 // Temporary password field
//                 const Text(
//                   'Temporary Password',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF2C2C2C),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildTextFormField(
//                   controller: _tempPasswordController,
//                   hintText: 'Enter your temporary password',
//                   prefixIcon: Icons.lock_outline,
//                   obscureText: _obscureTempPassword,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureTempPassword ? Icons.visibility_off : Icons.visibility,
//                       color: Colors.grey[600],
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscureTempPassword = !_obscureTempPassword;
//                       });
//                     },
//                   ),
//                   validator: (value) {
//                     if (value?.isEmpty ?? true) {
//                       return 'Temporary password is required';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),

//                 // New password field
//                 const Text(
//                   'New Password',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF2C2C2C),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildTextFormField(
//                   controller: _newPasswordController,
//                   hintText: 'Enter your new password',
//                   prefixIcon: Icons.lock,
//                   obscureText: _obscureNewPassword,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
//                       color: Colors.grey[600],
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscureNewPassword = !_obscureNewPassword;
//                       });
//                     },
//                   ),
//                   validator: (value) {
//                     if (value?.isEmpty ?? true) {
//                       return 'New password is required';
//                     }
//                     if (value!.length < 8) {
//                       return 'Password must be at least 8 characters';
//                     }
//                     if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
//                       return 'Password must contain uppercase, lowercase and number';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),

//                 // Confirm password field
//                 const Text(
//                   'Confirm New Password',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF2C2C2C),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildTextFormField(
//                   controller: _confirmPasswordController,
//                   hintText: 'Confirm your new password',
//                   prefixIcon: Icons.lock,
//                   obscureText: _obscureConfirmPassword,
//                   textInputAction: TextInputAction.done,
//                   onFieldSubmitted: (_) => _handlePasswordReset(),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
//                       color: Colors.grey[600],
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscureConfirmPassword = !_obscureConfirmPassword;
//                       });
//                     },
//                   ),
//                   validator: (value) {
//                     if (value?.isEmpty ?? true) {
//                       return 'Please confirm your password';
//                     }
//                     if (value != _newPasswordController.text) {
//                       return 'Passwords do not match';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 40),

//                 // Reset password button
//                 Obx(() {
//                   return SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: authController.isLoading ? null : _handlePasswordReset,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFD32F2F),
//                         disabledBackgroundColor: Colors.grey[400],
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 2,
//                       ),
//                       child: authController.isLoading
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                           : const Text(
//                               'RESET PASSWORD',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 letterSpacing: 1,
//                               ),
//                             ),
//                     ),
//                   );
//                 }),

//                 const SizedBox(height: 24),

//                 // Back to login
//                 Center(
//                   child: TextButton(
//                     onPressed: _goBackToLogin,
//                     child: const Text(
//                       'Back to Login',
//                       style: TextStyle(
//                         color: Color(0xFFD32F2F),
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextFormField({
//     required TextEditingController controller,
//     required String hintText,
//     required IconData prefixIcon,
//     String? Function(String?)? validator,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//     TextInputAction? textInputAction,
//     Widget? suffixIcon,
//     void Function(String)? onFieldSubmitted,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: TextFormField(
//         controller: controller,
//         obscureText: obscureText,
//         keyboardType: keyboardType,
//         textInputAction: textInputAction ?? TextInputAction.next,
//         onFieldSubmitted: onFieldSubmitted,
//         validator: validator,
//         decoration: InputDecoration(
//           hintText: hintText,
//           hintStyle: TextStyle(color: Colors.grey[600]),
//           prefixIcon: Icon(prefixIcon, color: const Color(0xFF5C5C5C)),
//           suffixIcon: suffixIcon,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//       ),
//     );
//   }
// }