abstract class AppStrings {
  static const String appName = 'N&D Smart SchoolPay';
  static const String appTagline = 'Smart School Fee Management';

  // Splash
  static const String splashFooter = 'Secure & Convenient Parent Portal';

  // Login
  static const String welcomeBack = 'Welcome Back';
  static const String signInSubtitle = 'Sign in to continue to Smart SchoolPay';
  static const String emailOrPhoneLabel = 'Email or Mobile Number';
  static const String emailOrPhoneHint = 'Enter email or phone number';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String forgotPassword = 'Forgot Password?';
  static const String signInButton = 'Sign In';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String registerNow = 'Register';

  // Register
  static const String createAccount = 'Create Account';
  static const String registerSubtitle = 'Register to manage your school fees';
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'Enter your email address';
  static const String mobileLabel = 'Mobile Number';
  static const String mobileHint = 'Enter 10-digit mobile number';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = 'Re-enter your password';
  static const String termsCheck = 'I agree to the Terms & Conditions';
  static const String createAccountButton = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signIn = 'Sign In';

  // Validation messages
  static const String reqFullName = 'Full name is required';
  static const String reqEmailOrPhone = 'Email or mobile number is required';
  static const String invalidEmailOrPhone = 'Enter a valid email or 10-digit mobile number';
  static const String reqEmail = 'Email address is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String reqMobile = 'Mobile number is required';
  static const String invalidMobile = 'Enter a valid 10-digit mobile number';
  static const String reqPassword = 'Password is required';
  static const String minPasswordLen = 'Password must be at least 6 characters';
  static const String reqConfirmPassword = 'Confirm password is required';
  static const String passwordMismatch = 'Passwords do not match';
  static const String mustAcceptTerms = 'You must accept the Terms & Conditions to proceed';

  // Authentication errors & demo hint
  static const String invalidCredentials = 'Invalid email or password';
  static const String demoAccountHintHeader = 'Demo Accounts (Development Only)';
  static const String demoAccountHintBody = 'Parent: parent@test.com | Password: Parent@123\nDriver: driver@test.com | Password: Driver@123';


  // Home Dashboard
  static const String greetingPrefix = 'Good Morning, ';
  static const String homeSubtitle = "Manage your child's school fees easily.";
  static const String studentTitle = 'Student';
  static const String viewDetails = 'View Details';
  static const String feeSummaryTitle = 'School Fee';
  static const String payNowButton = 'Pay Now';
  static const String quickActionsTitle = 'Quick Actions';
  static const String recentPaymentsTitle = 'Recent Payments';
  static const String upcomingFeeTitle = 'Next Payment';
  static const String latestUpdatesTitle = 'Latest Updates';
  static const String viewAll = 'View All';

  // Navigation Tabs
  static const String navHome = 'Home';
  static const String navPayments = 'Payments';
  static const String navNotifications = 'Notifications';
  static const String navProfile = 'Profile';
  static const String navReceipts = 'Receipts';

  // Module Placeholders
  static const String paymentModulePlaceholder = 'Payment module coming soon';
  static const String paymentHistoryPlaceholder = 'Payment history feature coming soon';
  static const String receiptsPlaceholder = 'Receipts feature coming soon';
  static const String notificationsPlaceholder = 'Notifications feature coming soon';

  // Placeholders
  static const String forgotPasswordNotice = 'Forgot password functionality will be available in the next release.';
  static const String mockLoginSuccess = 'Login successful! Navigating to home...';
  static const String mockRegistrationSuccess = 'Account created successfully! Please sign in.';

  // Driver Upgrade
  static const String becomeDriverDialogTitle = 'Become a School Van Driver';
  static const String becomeDriverDialogContent =
      'Update your profile to also register as a school van driver and manage student pickups.';
  static const String becomeDriverNotNow = 'Not Now';
  static const String becomeDriverUpdate = 'Update';
  static const String becomeDriverScreenTitle = 'Register as a Driver';
  static const String becomeDriverSubtitle =
      'Add your vehicle details to also drive for the school';
  static const String vanNumberLabel = 'Van Number';
  static const String vanNumberHint = 'e.g. WP NC-4821';
  static const String licenseNoLabel = 'License Number';
  static const String licenseNoHint = 'Enter your driving license number';
  static const String reqVanNumber = 'Van number is required';
  static const String reqLicenseNo = 'License number is required';
  static const String becomeDriverButton = 'Register as Driver';
  static const String becomeDriverSuccess =
      'You are now registered as a driver! You can switch modes from your Profile.';
  static const String becomeDriverError =
      'Registration failed. Please check details and try again.';

  // Role Switch
  static const String roleSwitchParent = 'Parent';
  static const String roleSwitchDriver = 'Driver';

  // Add Student
  static const String addStudentScreenTitle = 'Add Student';
  static const String addStudentSubtitle =
      'Register a child to manage their school fees and van pickup';
  static const String studentNameLabel = 'Student Name';
  static const String studentNameHint = "Enter student's full name";
  static const String reqStudentName = 'Student name is required';
  static const String gradeLabel = 'Grade / Class';
  static const String gradeHint = 'e.g. Grade 5-B';
  static const String sectionLabel = 'Section';
  static const String sectionHint = 'e.g. Section A';
  static const String schoolNameLabel = 'School Name';
  static const String schoolNameHint = 'Enter school name';
  static const String pickupLocationLabel = 'Pickup Location';
  static const String pickupLocationHint = 'Enter home address or pickup point';
  static const String addStudentButton = 'Add Student';
  static const String addStudentSuccessDialogTitle = 'Student Added!';
  static const String addStudentCodeNotice =
      "Share this code with your child's van driver so they can add your child to their route.";
  static const String copyCodeButton = 'Copy Code';
  static const String codeCopiedToast = 'Student code copied to clipboard!';
  static const String addStudentError =
      'Failed to add student. Please check details and try again.';
  static const String noStudentsTitle = 'No Students Added Yet';
  static const String noStudentsSubtitle =
      'Add your child to track fee payments and van pickup routes.';
  static const String addFirstStudentButton = 'Add Your First Student';
  static const String addStudentAction = 'Add Student';
}
