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
}
