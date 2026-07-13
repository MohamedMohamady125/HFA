import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';

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
      'successfully_registered': 'Successfully registered',
      'invalid_login': 'Invalid login',
      'ok': 'OK',
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
      'forgot_desc': "Enter your email and we'll send you a reset code.",
      'email_address': 'Email address',
      'send_reset': 'Send Reset Link',
      'reset_sent': 'Reset link sent!',
      'send_code': 'Send Code',
      'enter_reset_code': 'Enter Code',
      'code_sent_to_email': 'We sent a 6-digit code to',
      'code_expires_15': 'Code expires in 15 minutes',
      'verify_code': 'Verify Code',
      'resend_code': 'Resend Code',
      'new_password_title': 'New Password',
      'new_password_desc': 'Choose a new password for your account',
      'password_reset_success': 'Password reset successfully! You can now log in.',

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
      'view_calendar': 'View Calendar',
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

      // Language
      'language': 'Language',
      'language_current': 'English',

      // Nav
      'home': 'Home',
      'chat': 'Chat',
      'gear': 'Gear',
      'payments': 'Payments',
      'profile': 'Profile',
      'athletes': 'Athletes',
      'threads_nav': 'Threads',

      // Extra UI
      'hi': 'Hi',
      'switch_text': 'Switch',
      'view_full_calendar': 'View Full Attendance Calendar',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'new_email': 'New Email',
      'confirm_new_password': 'Confirm New Password',
      'update': 'Update',
      'email_updated': 'Email updated successfully',
      'email_update_failed': 'Failed to update email',
      'measurements_saved': 'Measurements saved!',
      'events_saved': 'Events saved!',
      'no_payment_records': 'No payment records yet',
      'branch_label': 'Branch',
      'no_payment': 'No payment',
      'athlete': 'Athlete',
      'monthly_attendance': 'Monthly Attendance',
      'body_measurements': 'Body Measurements',
      'swim_events_times': 'Swim Events & Times',
      'no_measurements': 'No measurements recorded yet',
      'no_swim_events': 'No swim events recorded yet',
      'rate': 'Rate',
      'of_sessions': 'sessions',
      'new_coach': 'New Coach',
      'password_auto_gen': 'Password will be auto-generated',
      'name_email_required': 'Name and email are required',
      'failed_to_load': 'Failed to load data',
      'coach_credentials': 'Coach Credentials',
      'share_credentials': 'Share these credentials with the coach',
      'copy_all': 'Copy All',
      'credentials_copied': 'Credentials copied!',
      'done': 'Done',
      'assign_branch': 'Assign Branch',
      'branch_assigned': 'Branch assigned',
      'remove_permanently': 'permanently?',
      'failed_generic': 'Failed',
      'failed_create_coach': 'Failed to create coach',
      'coaches': 'Coaches',
      'add_first_coach': 'Add your first coach',
      'credentials': 'Credentials',
      'unassigned': 'Unassigned',
      'copied': 'copied!',
      'switch_branch': 'Switch Branch',
      'approved_text': 'Approved!',
      'rejected_text': 'Rejected',
      'all_caught_up': 'All caught up!',
      'failed_to_approve': 'Failed to approve',
      'failed_to_reject': 'Failed to reject',
      'failed_load_sessions': 'Failed to load session dates',
      'no_gear_posted': 'No gear updates posted yet.',
      'error_loading_gear': 'Error loading gear information.',
      'no_gear_updates': 'No gear updates.',
      'no_posts': 'No posts yet.',
      'no_threads_available': 'No threads available.',
      'message_hint': 'Message',
      'confirm_password_label': 'Confirm Password',
      'created_text': 'created!',
      'server_error': 'Server error',

      // Branches
      'our_branches': 'Our Branches',
      'practice_schedule': 'Practice Schedule',
      'branch_tour': 'Branch Tour',
      'watch_video': 'Watch Video',
      'ready_to_join': 'Ready to join HFA?',
      'no_branches_found': 'No branches found',
      'failed_load_branches': 'Failed to load branches',

      // Manage Branches (head coach)
      'manage_branches': 'Manage Branches',
      'add_branch': 'Add Branch',
      'edit_branch': 'Edit Branch',
      'delete_branch': 'Delete Branch',
      'delete_branch_confirm': 'Are you sure you want to delete this branch?',
      'branch_name_label': 'Branch Name',
      'address': 'Address',
      'whatsapp': 'WhatsApp',
      'video_url_label': 'Video Link',
      'branch_saved': 'Branch saved',
      'branch_deleted': 'Branch deleted',
      'practice_schedule_helper': 'Each line or comma-separated entry appears as a bullet on the public page',

      // Health History
      'health_history': 'Health History',
      'health_history_desc': 'Track your medical records and conditions',
      'no_health_records': 'No health records yet',
      'tap_add_record': 'Tap + to add your first record',
      'new_health_record': 'New Health Record',
      'record_name': 'CONDITION NAME',
      'record_name_hint': 'e.g. Shoulder injury, Asthma...',
      'notes_label': 'NOTES',
      'notes_hint': 'Describe the condition, treatment, etc.',
      'attachments': 'PHOTOS',
      'max_2_photos': 'Up to 2 photos (medical reports, X-rays, etc.)',
      'save_record': 'Save Record',
      'record_created': 'Health record saved!',
      'enter_record_title': 'Please enter a condition name',
      'delete_health_record_confirm': 'Are you sure you want to delete this health record?',

      // Coach Notes
      'coach_notes': 'Coach Notes',
      'add_note': 'Add Note',
      'no_coach_notes': 'No coach notes yet',
      'coach_note_hint': 'Write your observations about this swimmer...',
      'add_coach_note': 'Add Coach Note',

      // Parent Access
      'parent_access': 'Parent Access',
      'parent_access_desc': 'Let your parent view your account',
      'generate_code': 'Generate Access Code',
      'your_code': 'YOUR ACCESS CODE',
      'code_expires': 'Valid for 72 hours',
      'copy_code': 'Copy Code',
      'new_code': 'New Code',
      'parent_login_desc': 'Enter the 6-digit code shared by the athlete to access their account.',
      'access_code': 'ACCESS CODE',
      'enter_code': 'Please enter a code',
      'invalid_code': 'Invalid or expired code',

      // Legal & Account
      'delete_account': 'Delete Account',
      'delete_account_desc': 'Permanently delete your account and all data',
      'delete_account_confirm': 'Are you sure you want to delete your account? This action cannot be undone.',
      'delete_account_password': 'Enter your password to confirm',
      'account_deleted': 'Account deleted successfully',
      'privacy_policy': 'Privacy Policy',

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications yet',
      'no_notifications_desc': 'You\'ll be notified when your coach posts updates',
      'mark_all_read': 'Mark all as read',
      'just_now': 'Just now',
      'minutes_ago': 'm ago',
      'hours_ago': 'h ago',
      'days_ago': 'd ago',
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
      'successfully_registered': '\u062a\u0645 \u0627\u0644\u062a\u0633\u062c\u064a\u0644 \u0628\u0646\u062c\u0627\u062d',
      'invalid_login': '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062f\u062e\u0648\u0644 \u063a\u064a\u0631 \u0635\u062d\u064a\u062d\u0629',
      'ok': '\u062d\u0633\u0646\u0627\u064b',
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
      'forgot_desc': '\u0623\u062f\u062e\u0644 \u0628\u0631\u064a\u062f\u0643 \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0648\u0633\u0646\u0631\u0633\u0644 \u0644\u0643 \u0631\u0645\u0632 \u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u062a\u0639\u064a\u064a\u0646.',
      'email_address': '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
      'send_reset': '\u0625\u0631\u0633\u0627\u0644 \u0631\u0627\u0628\u0637 \u0627\u0644\u062a\u0639\u064a\u064a\u0646',
      'reset_sent': '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0627\u0628\u0637!',
      'send_code': '\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0645\u0632',
      'enter_reset_code': '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0645\u0632',
      'code_sent_to_email': '\u0623\u0631\u0633\u0644\u0646\u0627 \u0631\u0645\u0632 \u0645\u0643\u0648\u0646 \u0645\u0646 \u0666 \u0623\u0631\u0642\u0627\u0645 \u0625\u0644\u0649',
      'code_expires_15': '\u064a\u0646\u062a\u0647\u064a \u0627\u0644\u0631\u0645\u0632 \u062e\u0644\u0627\u0644 \u0661\u0665 \u062f\u0642\u064a\u0642\u0629',
      'verify_code': '\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0631\u0645\u0632',
      'resend_code': '\u0625\u0639\u0627\u062f\u0629 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0645\u0632',
      'new_password_title': '\u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u062c\u062f\u064a\u062f\u0629',
      'new_password_desc': '\u0627\u062e\u062a\u0631 \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u062c\u062f\u064a\u062f\u0629 \u0644\u062d\u0633\u0627\u0628\u0643',
      'password_reset_success': '\u062a\u0645 \u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631! \u064a\u0645\u0643\u0646\u0643 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0627\u0644\u0622\u0646.',

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
      'view_calendar': '\u0639\u0631\u0636 \u0627\u0644\u062a\u0642\u0648\u064a\u0645',
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

      // Language
      'language': '\u0627\u0644\u0644\u063a\u0629',
      'language_current': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',

      // Nav
      'home': '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
      'chat': '\u0627\u0644\u0645\u062d\u0627\u062f\u062b\u0629',
      'gear': '\u0627\u0644\u0645\u0639\u062f\u0627\u062a',
      'payments': '\u0627\u0644\u0645\u062f\u0641\u0648\u0639\u0627\u062a',
      'profile': '\u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062e\u0635\u064a',
      'athletes': '\u0627\u0644\u0644\u0627\u0639\u0628\u0648\u0646',
      'threads_nav': '\u0627\u0644\u0645\u0648\u0627\u0636\u064a\u0639',

      // Extra UI
      'hi': '\u0645\u0631\u062d\u0628\u0627\u064b',
      'switch_text': '\u062a\u0628\u062f\u064a\u0644',
      'view_full_calendar': '\u0639\u0631\u0636 \u062a\u0642\u0648\u064a\u0645 \u0627\u0644\u062d\u0636\u0648\u0631 \u0627\u0644\u0643\u0627\u0645\u0644',
      'today': '\u0627\u0644\u064a\u0648\u0645',
      'yesterday': '\u0623\u0645\u0633',
      'new_email': '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u062c\u062f\u064a\u062f',
      'confirm_new_password': '\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062c\u062f\u064a\u062f\u0629',
      'update': '\u062a\u062d\u062f\u064a\u062b',
      'email_updated': '\u062a\u0645 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0628\u0631\u064a\u062f \u0628\u0646\u062c\u0627\u062d',
      'email_update_failed': '\u0641\u0634\u0644 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0628\u0631\u064a\u062f',
      'measurements_saved': '\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0642\u064a\u0627\u0633\u0627\u062a!',
      'events_saved': '\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0623\u062d\u062f\u0627\u062b!',
      'no_payment_records': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0633\u062c\u0644\u0627\u062a \u062f\u0641\u0639 \u0628\u0639\u062f',
      'branch_label': '\u0627\u0644\u0641\u0631\u0639',
      'no_payment': '\u0644\u0627 \u064a\u0648\u062c\u062f \u062f\u0641\u0639',
      'athlete': '\u0644\u0627\u0639\u0628',
      'monthly_attendance': '\u0627\u0644\u062d\u0636\u0648\u0631 \u0627\u0644\u0634\u0647\u0631\u064a',
      'body_measurements': '\u0627\u0644\u0642\u064a\u0627\u0633\u0627\u062a \u0627\u0644\u062c\u0633\u062f\u064a\u0629',
      'swim_events_times': '\u0623\u062d\u062f\u0627\u062b \u0627\u0644\u0633\u0628\u0627\u062d\u0629 \u0648\u0627\u0644\u0623\u0648\u0642\u0627\u062a',
      'no_measurements': '\u0644\u0645 \u064a\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0642\u064a\u0627\u0633\u0627\u062a \u0628\u0639\u062f',
      'no_swim_events': '\u0644\u0645 \u064a\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0623\u062d\u062f\u0627\u062b \u0633\u0628\u0627\u062d\u0629 \u0628\u0639\u062f',
      'rate': '\u0627\u0644\u0645\u0639\u062f\u0644',
      'of_sessions': '\u062c\u0644\u0633\u0627\u062a',
      'new_coach': '\u0645\u062f\u0631\u0628 \u062c\u062f\u064a\u062f',
      'password_auto_gen': '\u0633\u064a\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u062a\u0644\u0642\u0627\u0626\u064a\u0627\u064b',
      'name_email_required': '\u0627\u0644\u0627\u0633\u0645 \u0648\u0627\u0644\u0628\u0631\u064a\u062f \u0645\u0637\u0644\u0648\u0628\u0627\u0646',
      'failed_to_load': '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a',
      'coach_credentials': '\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0645\u062f\u0631\u0628',
      'share_credentials': '\u0634\u0627\u0631\u0643 \u0647\u0630\u0647 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0645\u0639 \u0627\u0644\u0645\u062f\u0631\u0628',
      'copy_all': '\u0646\u0633\u062e \u0627\u0644\u0643\u0644',
      'credentials_copied': '\u062a\u0645 \u0646\u0633\u062e \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a!',
      'done': '\u062a\u0645',
      'assign_branch': '\u062a\u0639\u064a\u064a\u0646 \u0627\u0644\u0641\u0631\u0639',
      'branch_assigned': '\u062a\u0645 \u062a\u0639\u064a\u064a\u0646 \u0627\u0644\u0641\u0631\u0639',
      'remove_permanently': '\u0646\u0647\u0627\u0626\u064a\u0627\u064b\u061f',
      'failed_generic': '\u0641\u0634\u0644',
      'failed_create_coach': '\u0641\u0634\u0644 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0645\u062f\u0631\u0628',
      'coaches': '\u0627\u0644\u0645\u062f\u0631\u0628\u0648\u0646',
      'add_first_coach': '\u0623\u0636\u0641 \u0623\u0648\u0644 \u0645\u062f\u0631\u0628',
      'credentials': '\u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a',
      'unassigned': '\u063a\u064a\u0631 \u0645\u0639\u064a\u0646',
      'copied': '\u062a\u0645 \u0627\u0644\u0646\u0633\u062e!',
      'switch_branch': '\u062a\u0628\u062f\u064a\u0644 \u0627\u0644\u0641\u0631\u0639',
      'approved_text': '\u062a\u0645\u062a \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629!',
      'rejected_text': '\u0645\u0631\u0641\u0648\u0636',
      'all_caught_up': '\u0644\u0627 \u064a\u0648\u062c\u062f \u0627\u0644\u0645\u0632\u064a\u062f!',
      'failed_to_approve': '\u0641\u0634\u0644\u062a \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629',
      'failed_to_reject': '\u0641\u0634\u0644 \u0627\u0644\u0631\u0641\u0636',
      'failed_load_sessions': '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u062c\u0644\u0633\u0627\u062a',
      'no_gear_posted': '\u0644\u0645 \u064a\u062a\u0645 \u0646\u0634\u0631 \u062a\u062d\u062f\u064a\u062b\u0627\u062a \u0627\u0644\u0645\u0639\u062f\u0627\u062a \u0628\u0639\u062f.',
      'error_loading_gear': '\u062e\u0637\u0623 \u0641\u064a \u062a\u062d\u0645\u064a\u0644 \u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u0645\u0639\u062f\u0627\u062a.',
      'no_gear_updates': '\u0644\u0627 \u062a\u0648\u062c\u062f \u062a\u062d\u062f\u064a\u062b\u0627\u062a \u0645\u0639\u062f\u0627\u062a.',
      'no_posts': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0646\u0634\u0648\u0631\u0627\u062a \u0628\u0639\u062f.',
      'no_threads_available': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0648\u0627\u0636\u064a\u0639.',
      'message_hint': '\u0631\u0633\u0627\u0644\u0629',
      'confirm_password_label': '\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
      'created_text': '\u062a\u0645 \u0625\u0646\u0634\u0627\u0624\u0647!',
      'server_error': '\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062e\u0627\u062f\u0645',

      // Branches
      'our_branches': '\u0641\u0631\u0648\u0639\u0646\u0627',
      'practice_schedule': '\u0645\u0648\u0627\u0639\u064a\u062f \u0627\u0644\u062a\u0645\u0631\u064a\u0646',
      'branch_tour': '\u062c\u0648\u0644\u0629 \u0627\u0644\u0641\u0631\u0639',
      'watch_video': '\u0645\u0634\u0627\u0647\u062f\u0629 \u0627\u0644\u0641\u064a\u062f\u064a\u0648',
      'ready_to_join': '\u0645\u0633\u062a\u0639\u062f \u0644\u0644\u0627\u0646\u0636\u0645\u0627\u0645 \u0625\u0644\u0649 HFA\u061f',
      'no_branches_found': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0641\u0631\u0648\u0639',
      'failed_load_branches': '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0641\u0631\u0648\u0639',

      // Manage Branches (head coach)
      'manage_branches': 'إدارة الفروع',
      'add_branch': 'إضافة فرع',
      'edit_branch': 'تعديل الفرع',
      'delete_branch': 'حذف الفرع',
      'delete_branch_confirm': 'هل أنت متأكد أنك تريد حذف هذا الفرع؟',
      'branch_name_label': 'اسم الفرع',
      'address': 'العنوان',
      'whatsapp': 'واتساب',
      'video_url_label': 'رابط الفيديو',
      'branch_saved': 'تم حفظ الفرع',
      'branch_deleted': 'تم حذف الفرع',
      'practice_schedule_helper': 'كل سطر أو عنصر مفصول بفاصلة يظهر كنقطة في الصفحة العامة',

      // Health History
      'health_history': '\u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u0635\u062d\u064a',
      'health_history_desc': '\u062a\u062a\u0628\u0639 \u0633\u062c\u0644\u0627\u062a\u0643 \u0627\u0644\u0637\u0628\u064a\u0629 \u0648\u062d\u0627\u0644\u0627\u062a\u0643 \u0627\u0644\u0635\u062d\u064a\u0629',
      'no_health_records': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0633\u062c\u0644\u0627\u062a \u0635\u062d\u064a\u0629 \u0628\u0639\u062f',
      'tap_add_record': '\u0627\u0636\u063a\u0637 + \u0644\u0625\u0636\u0627\u0641\u0629 \u0623\u0648\u0644 \u0633\u062c\u0644',
      'new_health_record': '\u0633\u062c\u0644 \u0635\u062d\u064a \u062c\u062f\u064a\u062f',
      'record_name': '\u0627\u0633\u0645 \u0627\u0644\u062d\u0627\u0644\u0629',
      'record_name_hint': '\u0645\u062b\u0644\u0627\u064b: \u0625\u0635\u0627\u0628\u0629 \u0627\u0644\u0643\u062a\u0641\u060c \u0631\u0628\u0648...',
      'notes_label': '\u0645\u0644\u0627\u062d\u0638\u0627\u062a',
      'notes_hint': '\u0648\u0635\u0641 \u0627\u0644\u062d\u0627\u0644\u0629 \u0648\u0627\u0644\u0639\u0644\u0627\u062c \u0648\u063a\u064a\u0631\u0647...',
      'attachments': '\u0635\u0648\u0631',
      'max_2_photos': '\u062d\u062a\u0649 \u0635\u0648\u0631\u062a\u064a\u0646 (\u062a\u0642\u0627\u0631\u064a\u0631 \u0637\u0628\u064a\u0629\u060c \u0623\u0634\u0639\u0629...)',
      'save_record': '\u062d\u0641\u0638 \u0627\u0644\u0633\u062c\u0644',
      'record_created': '\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u0635\u062d\u064a!',
      'enter_record_title': '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0633\u0645 \u0627\u0644\u062d\u0627\u0644\u0629',
      'delete_health_record_confirm': '\u0647\u0644 \u0623\u0646\u062a \u0645\u062a\u0623\u0643\u062f \u0645\u0646 \u062d\u0630\u0641 \u0647\u0630\u0627 \u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u0635\u062d\u064a\u061f',

      // Coach Notes
      'coach_notes': '\u0645\u0644\u0627\u062d\u0638\u0627\u062a \u0627\u0644\u0645\u062f\u0631\u0628',
      'add_note': '\u0625\u0636\u0627\u0641\u0629 \u0645\u0644\u0627\u062d\u0638\u0629',
      'no_coach_notes': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u0644\u0627\u062d\u0638\u0627\u062a \u0628\u0639\u062f',
      'coach_note_hint': '\u0627\u0643\u062a\u0628 \u0645\u0644\u0627\u062d\u0638\u0627\u062a\u0643 \u0639\u0646 \u0647\u0630\u0627 \u0627\u0644\u0633\u0628\u0627\u062d...',
      'add_coach_note': '\u0625\u0636\u0627\u0641\u0629 \u0645\u0644\u0627\u062d\u0638\u0629 \u0627\u0644\u0645\u062f\u0631\u0628',

      // Parent Access
      'parent_access': '\u062f\u062e\u0648\u0644 \u0648\u0644\u064a \u0627\u0644\u0623\u0645\u0631',
      'parent_access_desc': '\u0627\u0633\u0645\u062d \u0644\u0648\u0627\u0644\u062f\u0643 \u0628\u0645\u0634\u0627\u0647\u062f\u0629 \u062d\u0633\u0627\u0628\u0643',
      'generate_code': '\u0625\u0646\u0634\u0627\u0621 \u0631\u0645\u0632 \u0627\u0644\u062f\u062e\u0648\u0644',
      'your_code': '\u0631\u0645\u0632 \u0627\u0644\u062f\u062e\u0648\u0644',
      'code_expires': '\u0635\u0627\u0644\u062d \u0644\u0645\u062f\u0629 \u0667\u0662 \u0633\u0627\u0639\u0629',
      'copy_code': '\u0646\u0633\u062e \u0627\u0644\u0631\u0645\u0632',
      'new_code': '\u0631\u0645\u0632 \u062c\u062f\u064a\u062f',
      'parent_login_desc': '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0645\u0632 \u0627\u0644\u0645\u0643\u0648\u0646 \u0645\u0646 \u0666 \u0623\u062d\u0631\u0641 \u0627\u0644\u0630\u064a \u0634\u0627\u0631\u0643\u0647 \u0627\u0644\u0644\u0627\u0639\u0628 \u0644\u0644\u062f\u062e\u0648\u0644 \u0625\u0644\u0649 \u062d\u0633\u0627\u0628\u0647.',
      'access_code': '\u0631\u0645\u0632 \u0627\u0644\u062f\u062e\u0648\u0644',
      'enter_code': '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0644\u0631\u0645\u0632',
      'invalid_code': '\u0631\u0645\u0632 \u063a\u064a\u0631 \u0635\u0627\u0644\u062d \u0623\u0648 \u0645\u0646\u062a\u0647\u064a \u0627\u0644\u0635\u0644\u0627\u062d\u064a\u0629',

      // Legal & Account
      'delete_account': '\u062d\u0630\u0641 \u0627\u0644\u062d\u0633\u0627\u0628',
      'delete_account_desc': '\u062d\u0630\u0641 \u062d\u0633\u0627\u0628\u0643 \u0648\u062c\u0645\u064a\u0639 \u0628\u064a\u0627\u0646\u0627\u062a\u0643 \u0646\u0647\u0627\u0626\u064a\u0627\u064b',
      'delete_account_confirm': '\u0647\u0644 \u0623\u0646\u062a \u0645\u062a\u0623\u0643\u062f \u0645\u0646 \u062d\u0630\u0641 \u062d\u0633\u0627\u0628\u0643\u061f \u0644\u0627 \u064a\u0645\u0643\u0646 \u0627\u0644\u062a\u0631\u0627\u062c\u0639 \u0639\u0646 \u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621.',
      'delete_account_password': '\u0623\u062f\u062e\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0644\u0644\u062a\u0623\u0643\u064a\u062f',
      'account_deleted': '\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u062d\u0633\u0627\u0628 \u0628\u0646\u062c\u0627\u062d',
      'privacy_policy': '\u0633\u064a\u0627\u0633\u0629 \u0627\u0644\u062e\u0635\u0648\u0635\u064a\u0629',

      // Notifications
      'notifications': '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062a',
      'no_notifications': '\u0644\u0627 \u062a\u0648\u062c\u062f \u0625\u0634\u0639\u0627\u0631\u0627\u062a',
      'no_notifications_desc': '\u0633\u064a\u062a\u0645 \u0625\u0634\u0639\u0627\u0631\u0643 \u0639\u0646\u062f \u0646\u0634\u0631 \u0627\u0644\u0645\u062f\u0631\u0628 \u0644\u062a\u062d\u062f\u064a\u062b\u0627\u062a',
      'mark_all_read': '\u062a\u0639\u064a\u064a\u0646 \u0627\u0644\u0643\u0644 \u0643\u0645\u0642\u0631\u0648\u0621',
      'just_now': '\u0627\u0644\u0622\u0646',
      'minutes_ago': '\u062f \u0645\u0636\u062a',
      'hours_ago': '\u0633 \u0645\u0636\u062a',
      'days_ago': '\u064a \u0645\u0636\u062a',
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
  bool _initialized = false;

  Locale get locale => _locale;

  LocaleProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_locale');
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      // Auto-detect device language
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      _locale = deviceLocale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
    }
    _initialized = true;
    notifyListeners();
  }

  void toggleLocale() async {
    _locale = _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', _locale.languageCode);
    notifyListeners();
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale.languageCode);
    notifyListeners();
    // Re-register device token so push notifications use the new language
    PushNotificationService.registerDevice();
  }
}
