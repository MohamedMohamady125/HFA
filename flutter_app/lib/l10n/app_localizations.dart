import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Guest Home
      'welcome_title': 'Welcome to HFA!',
      'branch_count': 'We have 9 branches across Cairo and Giza!',
      'nearest_branch': 'Nearest Branch',
      'branch_name': 'Main Branch - Downtown',
      'practice_time': 'Practice Time: Mon-Fri, 4PM-6PM',
      'login': 'Login',
      'register': "Don't have an account? Register",
      'view_branches': 'View Our Branches',
      'coach_login': 'Coach Login',
      'swimming_academy': 'SWIMMING ACADEMY',

      // Login
      'welcome_back': 'Welcome Back',
      'sign_in_athlete': 'Sign in to your athlete account',
      'email': 'EMAIL',
      'password': 'PASSWORD',
      'enter_email': 'your@email.com',
      'enter_password': 'Enter your password',
      'forgot_password': 'Forgot password?',
      'sign_in': 'Sign In',
      'no_account': "Don't have an account? ",
      'register_now': 'Register',
      'logging_in': 'Logging in...',
      'fill_all_fields': 'Please fill in all fields',
      'athletes_only': 'Only athletes can login here.',
      'login_failed': 'Login failed',

      // Register
      'create_account': 'Create Account',
      'join_academy': 'Join our swimming academy',
      'full_name': 'FULL NAME',
      'phone': 'PHONE',
      'confirm_password': 'CONFIRM PASSWORD',
      'branch': 'BRANCH',
      'select_branch': 'Select your branch',
      'submit_registration': 'Submit Registration',
      'registration_submitted': 'Registration submitted! A coach will review your request.',
      'passwords_no_match': 'Passwords do not match.',
      'registration_info': 'Your registration will be reviewed by our coaching team.',

      // Admin / Coach Login
      'coach_portal': 'Coach Portal',
      'access_dashboard': 'Access your coaching dashboard',
      'coaches_only': 'Only coaches can access this page.',

      // Head Coach
      'head_coach': 'Head Coach',
      'head_coach_login': 'Head Coach Login',
      'head_coach_only': 'Only head coach can login here.',
      'select_branch_manage': 'Select a branch to manage',
      'manage_coaches': 'Manage Coaches',
      'switching_branch': 'Switching branch...',
      'loading_branches': 'Loading branches...',
      'no_branches': 'No branches available.',
      'failed_switch': 'Failed to switch branch',

      // Pending
      'pending_approval': 'Pending Approval',
      'pending_message': 'Your registration is being reviewed by a coach.\nYou will be notified once approved.',
      'logout': 'Logout',

      // Reset Password
      'reset_password': 'Reset Password',
      'forgot_desc': "Enter your email and we'll send you a reset link.",
      'email_address': 'Email address',
      'send_reset': 'Send Reset Link',
      'reset_sent': 'Reset link sent!',

      // Change Password
      'change_email': 'Change Email',
      'change_password': 'Change Password',
      'current_password': 'CURRENT PASSWORD',
      'new_password': 'NEW PASSWORD',
      'update_password': 'Update Password',
      'password_changed': 'Password changed successfully.',
      'password_failed': 'Failed to change password.',

      // Dashboard (Athlete)
      'dashboard': 'Dashboard',
      'weekly_attendance': 'Weekly Attendance',
      'latest_thread': 'Latest Thread',
      'gear_check': 'Gear Check',
      'payment': 'Payment',
      'status': 'Status',
      'paid': 'Paid',
      'late': 'Late',
      'pending': 'Pending',
      'unknown': 'Unknown',
      'loading': 'Loading...',
      'loading_dashboard': 'Loading dashboard...',
      'day': 'Day',
      'present': 'Present',
      'absent': 'Absent',

      // Threads
      'threads': 'Threads',
      'loading_threads': 'Loading threads...',
      'no_threads': 'No threads available',
      'no_messages': 'No messages yet',

      // Gear
      'gear_update': 'Gear Update',
      'gear_subtitle': 'Latest gear requirements from your coach',
      'loading_gear': 'Loading gear...',

      // Profile
      'attendance_tracker': 'Attendance',
      'measurements': 'Measurements',
      'save_measurements': 'Save Measurements',
      'edit': 'Edit',
      'swim_events': 'Swim Events',
      'add_event': 'Add Event',
      'save_events': 'Save Events',
      'event_name': 'Event',
      'time': 'Time',
      'height': 'Height (cm)',
      'weight': 'Weight (kg)',
      'arm': 'Arm (cm)',
      'leg': 'Leg (cm)',
      'fat': 'Fat %',
      'muscle': 'Muscle %',
      'saved': 'Saved!',
      'save_failed': 'Could not save',

      // Coach Home
      'coach_dashboard': 'Coach Dashboard',
      'quick_actions': 'Quick Actions',
      'registration_requests': 'Registration Requests',
      'payment_tracking': 'Payment Tracking',
      'attendance': 'Attendance',

      // Coach Threads
      'branch_chat': 'Branch Chat',
      'messages': 'messages',
      'type_message': 'Type a message...',

      // Coach Gear
      'weekly_gear_update': 'Gear Update',
      'enter_gear': 'Enter gear requirements for your athletes...',
      'save_gear': 'Save Gear Info',
      'saving': 'Saving...',
      'gear_saved': 'Gear info saved!',
      'gear_failed': 'Failed to post gear.',

      // Coach Profile
      'coach_profile': 'Coach Profile',
      'settings': 'Settings',
      'edit_profile': 'Edit Profile',
      'attendance_summary': 'Branch Attendance Summary',

      // Edit Profile
      'name': 'NAME',
      'save_changes': 'Save Changes',
      'profile_updated': 'Profile updated.',
      'profile_failed': 'Failed to update.',

      // Registration Requests
      'pending_requests': 'Registration Requests',
      'no_requests': 'No pending requests',
      'approve': 'Approve',
      'reject': 'Reject',
      'reject_confirm': 'Reject Request?',
      'reject_desc': 'This will permanently reject the registration.',
      'cancel': 'Cancel',
      'athlete_approved': 'Athlete approved',
      'request_rejected': 'Request rejected',

      // Payment
      'search_athlete': 'Search athlete...',
      'no_athletes': 'No athletes found.',

      // Attendance
      'weekly_attendance_title': 'Weekly Attendance',
      'loading_attendance': 'Loading attendance...',
      'no_branch': 'No branch assigned',

      // Attendance Summary
      'attendance_summary_title': 'Attendance Summary',
      'loading_summary': 'Loading summary...',

      // Manage Coaches
      'add_coach': 'Add Coach',
      'no_coaches': 'No coaches yet',
      'tap_add': 'Tap + to add one',
      'create_coach': 'Create Coach',
      'edit_coach': 'Edit Coach',
      'delete_coach': 'Delete Coach',
      'delete_confirm': 'Are you sure you want to delete',
      'delete': 'Delete',
      'create': 'Create',
      'save': 'Save',
      'reset': 'Reset',
      'reset_password_for': 'Reset Password for',
      'coach_created': 'Coach created',
      'coach_updated': 'Coach updated',
      'coach_deleted': 'Coach deleted',
      'password_reset_done': 'Password reset',
      'loading_coaches': 'Loading coaches...',

      // Nav
      'home': 'Home',
      'chat': 'Chat',
      'gear': 'Gear',
      'payments': 'Payments',
      'profile': 'Profile',
    },
    'ar': {
      // Guest Home
      'welcome_title': '\u0645\u0631\u062d\u0628\u064b\u0627 \u0628\u0643 \u0641\u064a HFA!',
      'branch_count': '\u0644\u062f\u064a\u0646\u0627 \u0669 \u0641\u0631\u0648\u0639 \u0641\u064a \u0627\u0644\u0642\u0627\u0647\u0631\u0629 \u0648\u0627\u0644\u062c\u064a\u0632\u0629!',
      'nearest_branch': '\u0623\u0642\u0631\u0628 \u0641\u0631\u0639',
      'branch_name': '\u0627\u0644\u0641\u0631\u0639 \u0627\u0644\u0631\u0626\u064a\u0633\u064a - \u0648\u0633\u0637 \u0627\u0644\u0628\u0644\u062f',
      'practice_time': '\u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u062a\u0645\u0631\u064a\u0646: \u0645\u0646 \u0627\u0644\u0625\u062b\u0646\u064a\u0646 \u0625\u0644\u0649 \u0627\u0644\u062c\u0645\u0639\u0629\u060c \u0664 \u0625\u0644\u0649 \u0666 \u0645\u0633\u0627\u0621\u064b',
      'login': '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
      'register': '\u0644\u064a\u0633 \u0644\u062f\u064a\u0643 \u062d\u0633\u0627\u0628\u061f \u0633\u062c\u0644 \u0627\u0644\u0622\u0646',
      'view_branches': '\u0639\u0631\u0636 \u062c\u0645\u064a\u0639 \u0627\u0644\u0641\u0631\u0648\u0639',
      'coach_login': '\u062f\u062e\u0648\u0644 \u0627\u0644\u0645\u062f\u0631\u0628',
      'swimming_academy': '\u0623\u0643\u0627\u062f\u064a\u0645\u064a\u0629 \u0627\u0644\u0633\u0628\u0627\u062d\u0629',

      // Login
      'welcome_back': '\u0645\u0631\u062d\u0628\u064b\u0627 \u0628\u0639\u0648\u062f\u062a\u0643',
      'sign_in_athlete': '\u0633\u062c\u0644 \u062f\u062e\u0648\u0644\u0643 \u0625\u0644\u0649 \u062d\u0633\u0627\u0628 \u0627\u0644\u0644\u0627\u0639\u0628',
      'email': '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
      'password': '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'enter_email': '\u0623\u062f\u062e\u0644 \u0628\u0631\u064a\u062f\u0643 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
      'enter_password': '\u0623\u062f\u062e\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'forgot_password': '\u0646\u0633\u064a\u062a \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631\u061f',
      'sign_in': '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
      'no_account': '\u0644\u064a\u0633 \u0644\u062f\u064a\u0643 \u062d\u0633\u0627\u0628\u061f ',
      'register_now': '\u0633\u062c\u0644 \u0627\u0644\u0622\u0646',
      'logging_in': '\u062c\u0627\u0631\u064a \u0627\u0644\u062f\u062e\u0648\u0644...',
      'fill_all_fields': '\u064a\u0631\u062c\u0649 \u0645\u0644\u0621 \u062c\u0645\u064a\u0639 \u0627\u0644\u062d\u0642\u0648\u0644',
      'athletes_only': '\u0641\u0642\u0637 \u0627\u0644\u0644\u0627\u0639\u0628\u064a\u0646 \u064a\u0645\u0643\u0646\u0647\u0645 \u0627\u0644\u062f\u062e\u0648\u0644 \u0647\u0646\u0627.',
      'login_failed': '\u0641\u0634\u0644 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',

      // Register
      'create_account': '\u0625\u0646\u0634\u0627\u0621 \u062d\u0633\u0627\u0628',
      'join_academy': '\u0627\u0646\u0636\u0645 \u0625\u0644\u0649 \u0623\u0643\u0627\u062f\u064a\u0645\u064a\u0629 \u0627\u0644\u0633\u0628\u0627\u062d\u0629',
      'full_name': '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
      'phone': '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062a\u0641',
      'confirm_password': '\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'branch': '\u0627\u0644\u0641\u0631\u0639',
      'select_branch': '\u0627\u062e\u062a\u0631 \u0641\u0631\u0639\u0643',
      'submit_registration': '\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u062a\u0633\u062c\u064a\u0644',
      'registration_submitted': '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u062a\u0633\u062c\u064a\u0644! \u0633\u064a\u0631\u0627\u062c\u0639\u0647 \u0627\u0644\u0645\u062f\u0631\u0628.',
      'passwords_no_match': '\u0643\u0644\u0645\u0627\u062a \u0627\u0644\u0645\u0631\u0648\u0631 \u063a\u064a\u0631 \u0645\u062a\u0637\u0627\u0628\u0642\u0629.',
      'registration_info': '\u0633\u064a\u062a\u0645 \u0645\u0631\u0627\u062c\u0639\u0629 \u062a\u0633\u062c\u064a\u0644\u0643 \u0645\u0646 \u0642\u0628\u0644 \u0641\u0631\u064a\u0642 \u0627\u0644\u062a\u062f\u0631\u064a\u0628.',

      // Admin / Coach Login
      'coach_portal': '\u0628\u0648\u0627\u0628\u0629 \u0627\u0644\u0645\u062f\u0631\u0628',
      'access_dashboard': '\u0627\u0644\u0648\u0635\u0648\u0644 \u0625\u0644\u0649 \u0644\u0648\u062d\u0629 \u0627\u0644\u062a\u062d\u0643\u0645',
      'coaches_only': '\u0641\u0642\u0637 \u0627\u0644\u0645\u062f\u0631\u0628\u064a\u0646 \u064a\u0645\u0643\u0646\u0647\u0645 \u0627\u0644\u0648\u0635\u0648\u0644.',

      // Head Coach
      'head_coach': '\u0627\u0644\u0645\u062f\u0631\u0628 \u0627\u0644\u0631\u0626\u064a\u0633\u064a',
      'head_coach_login': '\u062f\u062e\u0648\u0644 \u0627\u0644\u0645\u062f\u0631\u0628 \u0627\u0644\u0631\u0626\u064a\u0633\u064a',
      'head_coach_only': '\u0641\u0642\u0637 \u0627\u0644\u0645\u062f\u0631\u0628 \u0627\u0644\u0631\u0626\u064a\u0633\u064a \u064a\u0645\u0643\u0646\u0647 \u0627\u0644\u062f\u062e\u0648\u0644.',
      'select_branch_manage': '\u0627\u062e\u062a\u0631 \u0641\u0631\u0639 \u0644\u0625\u062f\u0627\u0631\u062a\u0647',
      'manage_coaches': '\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0645\u062f\u0631\u0628\u064a\u0646',
      'switching_branch': '\u062c\u0627\u0631\u064a \u0627\u0644\u062a\u0628\u062f\u064a\u0644...',
      'loading_branches': '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0641\u0631\u0648\u0639...',
      'no_branches': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0641\u0631\u0648\u0639.',
      'failed_switch': '\u0641\u0634\u0644 \u062a\u0628\u062f\u064a\u0644 \u0627\u0644\u0641\u0631\u0639',

      // Pending
      'pending_approval': '\u0628\u0627\u0646\u062a\u0638\u0627\u0631 \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629',
      'pending_message': '\u062a\u0633\u062c\u064a\u0644\u0643 \u0642\u064a\u062f \u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0629 \u0645\u0646 \u0642\u0628\u0644 \u0645\u062f\u0631\u0628.\n\u0633\u064a\u062a\u0645 \u0625\u0628\u0644\u0627\u063a\u0643 \u0639\u0646\u062f \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629.',
      'logout': '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c',

      // Reset Password
      'reset_password': '\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'forgot_desc': '\u0623\u062f\u062e\u0644 \u0628\u0631\u064a\u062f\u0643 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0648\u0633\u0646\u0631\u0633\u0644 \u0644\u0643 \u0631\u0627\u0628\u0637 \u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u062a\u0639\u064a\u064a\u0646.',
      'email_address': '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
      'send_reset': '\u0625\u0631\u0633\u0627\u0644 \u0631\u0627\u0628\u0637 \u0627\u0644\u062a\u0639\u064a\u064a\u0646',
      'reset_sent': '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0627\u0628\u0637!',

      // Change Password
      'change_email': '\u062a\u063a\u064a\u064a\u0631 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
      'change_password': '\u062a\u063a\u064a\u064a\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'current_password': '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062d\u0627\u0644\u064a\u0629',
      'new_password': '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062c\u062f\u064a\u062f\u0629',
      'update_password': '\u062a\u062d\u062f\u064a\u062b \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'password_changed': '\u062a\u0645 \u062a\u063a\u064a\u064a\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0628\u0646\u062c\u0627\u062d.',
      'password_failed': '\u0641\u0634\u0644 \u062a\u063a\u064a\u064a\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631.',

      // Dashboard (Athlete)
      'dashboard': '\u0644\u0648\u062d\u0629 \u0627\u0644\u062a\u062d\u0643\u0645',
      'weekly_attendance': '\u0627\u0644\u062d\u0636\u0648\u0631 \u0627\u0644\u0623\u0633\u0628\u0648\u0639\u064a',
      'latest_thread': '\u0622\u062e\u0631 \u0645\u0648\u0636\u0648\u0639',
      'gear_check': '\u0641\u062d\u0635 \u0627\u0644\u0645\u0639\u062f\u0627\u062a',
      'payment': '\u0627\u0644\u062f\u0641\u0639',
      'status': '\u0627\u0644\u062d\u0627\u0644\u0629',
      'paid': '\u0645\u062f\u0641\u0648\u0639',
      'late': '\u0645\u062a\u0623\u062e\u0631',
      'pending': '\u0642\u064a\u062f \u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631',
      'unknown': '\u063a\u064a\u0631 \u0645\u0639\u0631\u0648\u0641',
      'loading': '\u062c\u0627\u0631\u064a \u0627\u0644\u062a\u062d\u0645\u064a\u0644...',
      'loading_dashboard': '\u062a\u062d\u0645\u064a\u0644 \u0644\u0648\u062d\u0629 \u0627\u0644\u062a\u062d\u0643\u0645...',
      'day': '\u064a\u0648\u0645',
      'present': '\u062d\u0627\u0636\u0631',
      'absent': '\u063a\u0627\u0626\u0628',

      // Threads
      'threads': '\u0627\u0644\u0645\u0648\u0627\u0636\u064a\u0639',
      'loading_threads': '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0645\u0648\u0627\u0636\u064a\u0639...',
      'no_threads': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0648\u0627\u0636\u064a\u0639',
      'no_messages': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u0633\u0627\u0626\u0644',

      // Gear
      'gear_update': '\u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0645\u0639\u062f\u0627\u062a',
      'gear_subtitle': '\u0645\u062a\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u0639\u062f\u0627\u062a \u0645\u0646 \u0645\u062f\u0631\u0628\u0643',
      'loading_gear': '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0645\u0639\u062f\u0627\u062a...',

      // Profile
      'attendance_tracker': '\u0627\u0644\u062d\u0636\u0648\u0631',
      'measurements': '\u0627\u0644\u0642\u064a\u0627\u0633\u0627\u062a',
      'save_measurements': '\u062d\u0641\u0638 \u0627\u0644\u0642\u064a\u0627\u0633\u0627\u062a',
      'edit': '\u062a\u0639\u062f\u064a\u0644',
      'swim_events': '\u0623\u062d\u062f\u0627\u062b \u0627\u0644\u0633\u0628\u0627\u062d\u0629',
      'add_event': '\u0625\u0636\u0627\u0641\u0629 \u062d\u062f\u062b',
      'save_events': '\u062d\u0641\u0638 \u0627\u0644\u0623\u062d\u062f\u0627\u062b',
      'event_name': '\u0627\u0644\u062d\u062f\u062b',
      'time': '\u0627\u0644\u0648\u0642\u062a',
      'height': '\u0627\u0644\u0637\u0648\u0644 (\u0633\u0645)',
      'weight': '\u0627\u0644\u0648\u0632\u0646 (\u0643\u062c)',
      'arm': '\u0627\u0644\u0630\u0631\u0627\u0639 (\u0633\u0645)',
      'leg': '\u0627\u0644\u0633\u0627\u0642 (\u0633\u0645)',
      'fat': '\u0646\u0633\u0628\u0629 \u0627\u0644\u062f\u0647\u0648\u0646 %',
      'muscle': '\u0646\u0633\u0628\u0629 \u0627\u0644\u0639\u0636\u0644\u0627\u062a %',
      'saved': '\u062a\u0645 \u0627\u0644\u062d\u0641\u0638!',
      'save_failed': '\u0641\u0634\u0644 \u0627\u0644\u062d\u0641\u0638',

      // Coach Home
      'coach_dashboard': '\u0644\u0648\u062d\u0629 \u0627\u0644\u0645\u062f\u0631\u0628',
      'quick_actions': '\u0625\u062c\u0631\u0627\u0621\u0627\u062a \u0633\u0631\u064a\u0639\u0629',
      'registration_requests': '\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u062a\u0633\u062c\u064a\u0644',
      'payment_tracking': '\u062a\u062a\u0628\u0639 \u0627\u0644\u0645\u062f\u0641\u0648\u0639\u0627\u062a',
      'attendance': '\u0627\u0644\u062d\u0636\u0648\u0631',

      // Coach Threads
      'branch_chat': '\u0645\u062d\u0627\u062f\u062b\u0629 \u0627\u0644\u0641\u0631\u0639',
      'messages': '\u0631\u0633\u0627\u0626\u0644',
      'type_message': '\u0627\u0643\u062a\u0628 \u0631\u0633\u0627\u0644\u0629...',

      // Coach Gear
      'weekly_gear_update': '\u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0645\u0639\u062f\u0627\u062a',
      'enter_gear': '\u0623\u062f\u062e\u0644 \u0645\u062a\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u0639\u062f\u0627\u062a \u0644\u0644\u0627\u0639\u0628\u064a\u0646...',
      'save_gear': '\u062d\u0641\u0638 \u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u0645\u0639\u062f\u0627\u062a',
      'saving': '\u062c\u0627\u0631\u064a \u0627\u0644\u062d\u0641\u0638...',
      'gear_saved': '\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0645\u0639\u062f\u0627\u062a!',
      'gear_failed': '\u0641\u0634\u0644 \u0646\u0634\u0631 \u0627\u0644\u0645\u0639\u062f\u0627\u062a.',

      // Coach Profile
      'coach_profile': '\u0645\u0644\u0641 \u0627\u0644\u0645\u062f\u0631\u0628',
      'settings': '\u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a',
      'edit_profile': '\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062e\u0635\u064a',
      'attendance_summary': '\u0645\u0644\u062e\u0635 \u062d\u0636\u0648\u0631 \u0627\u0644\u0641\u0631\u0639',

      // Edit Profile
      'name': '\u0627\u0644\u0627\u0633\u0645',
      'save_changes': '\u062d\u0641\u0638 \u0627\u0644\u062a\u063a\u064a\u064a\u0631\u0627\u062a',
      'profile_updated': '\u062a\u0645 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0645\u0644\u0641.',
      'profile_failed': '\u0641\u0634\u0644 \u0627\u0644\u062a\u062d\u062f\u064a\u062b.',

      // Registration Requests
      'pending_requests': '\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u062a\u0633\u062c\u064a\u0644',
      'no_requests': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0637\u0644\u0628\u0627\u062a',
      'approve': '\u0645\u0648\u0627\u0641\u0642\u0629',
      'reject': '\u0631\u0641\u0636',
      'reject_confirm': '\u0631\u0641\u0636 \u0627\u0644\u0637\u0644\u0628\u061f',
      'reject_desc': '\u0633\u064a\u062a\u0645 \u0631\u0641\u0636 \u0637\u0644\u0628 \u0627\u0644\u062a\u0633\u062c\u064a\u0644 \u0646\u0647\u0627\u0626\u064a\u064b\u0627.',
      'cancel': '\u0625\u0644\u063a\u0627\u0621',
      'athlete_approved': '\u062a\u0645\u062a \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0639\u0644\u0649 \u0627\u0644\u0644\u0627\u0639\u0628',
      'request_rejected': '\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0637\u0644\u0628',

      // Payment
      'search_athlete': '\u0628\u062d\u062b \u0639\u0646 \u0644\u0627\u0639\u0628...',
      'no_athletes': '\u0644\u0627 \u064a\u0648\u062c\u062f \u0644\u0627\u0639\u0628\u064a\u0646.',

      // Attendance
      'weekly_attendance_title': '\u0627\u0644\u062d\u0636\u0648\u0631 \u0627\u0644\u0623\u0633\u0628\u0648\u0639\u064a',
      'loading_attendance': '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u062d\u0636\u0648\u0631...',
      'no_branch': '\u0644\u0627 \u064a\u0648\u062c\u062f \u0641\u0631\u0639 \u0645\u0639\u064a\u0646',

      // Attendance Summary
      'attendance_summary_title': '\u0645\u0644\u062e\u0635 \u0627\u0644\u062d\u0636\u0648\u0631',
      'loading_summary': '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0645\u0644\u062e\u0635...',

      // Manage Coaches
      'add_coach': '\u0625\u0636\u0627\u0641\u0629 \u0645\u062f\u0631\u0628',
      'no_coaches': '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u062f\u0631\u0628\u064a\u0646',
      'tap_add': '\u0627\u0636\u063a\u0637 + \u0644\u0625\u0636\u0627\u0641\u0629',
      'create_coach': '\u0625\u0646\u0634\u0627\u0621 \u0645\u062f\u0631\u0628',
      'edit_coach': '\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u062f\u0631\u0628',
      'delete_coach': '\u062d\u0630\u0641 \u0627\u0644\u0645\u062f\u0631\u0628',
      'delete_confirm': '\u0647\u0644 \u0623\u0646\u062a \u0645\u062a\u0623\u0643\u062f \u0645\u0646 \u062d\u0630\u0641',
      'delete': '\u062d\u0630\u0641',
      'create': '\u0625\u0646\u0634\u0627\u0621',
      'save': '\u062d\u0641\u0638',
      'reset': '\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646',
      'reset_password_for': '\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0644\u0640',
      'coach_created': '\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0645\u062f\u0631\u0628',
      'coach_updated': '\u062a\u0645 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0645\u062f\u0631\u0628',
      'coach_deleted': '\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0645\u062f\u0631\u0628',
      'password_reset_done': '\u062a\u0645 \u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'loading_coaches': '\u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0645\u062f\u0631\u0628\u064a\u0646...',

      // Nav
      'home': '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
      'chat': '\u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0629',
      'gear': '\u0627\u0644\u0645\u0639\u062f\u0627\u062a',
      'payments': '\u0627\u0644\u0645\u062f\u0641\u0648\u0639\u0627\u062a',
      'profile': '\u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062e\u0635\u064a',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void toggleLocale() {
    _locale = _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
