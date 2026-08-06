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
      'branch_count': 'We have branches across Cairo and Giza!',
      'nearest_branch': 'Nearest Branch',
      'branch_name': 'Main Branch - Downtown',
      'practice_time': 'Practice Time: Mon-Fri, 4PM-6PM',
      'login': 'Login',
      'register': "Don't have an account? Register",
      'view_branches': 'View Our Branches',
      'coach_login': 'Coach Login',
      'swimming_academy': 'SWIMMING ACADEMY',
      'fitness_academy': 'FITNESS ACADEMY',

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
      'join_academy': 'Join our fitness academy',
      'full_name': 'FULL NAME',
      'phone': 'PHONE',
      'phone_optional': 'PHONE (OPTIONAL)',
      'phone_verify_hint': 'Strongly recommended \u2014 your coach uses your phone number to verify your identity and approve your registration quickly. Without it, your approval may be delayed until you verify in person at your branch.',
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
      'registration_rejected': 'Registration Not Accepted',
      'registration_rejected_message': 'Unfortunately, your registration was not accepted. You may register again at any time.',
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
      'latest_chat': 'Latest Chat',
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

      // Chat
      'threads': 'Chat',
      'loading_threads': 'Loading chat...',
      'no_threads': 'No chat available',
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

      // Coach Chat
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
      'threads_nav': 'Chat',

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
      'no_threads_available': 'No chat available.',
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
      'terms_of_service': 'Terms of Service',
      'agree_terms_prefix': 'By registering, you agree to our ',
      'and_word': ' and ',

      // Offline
      'no_connection': 'No connection',
      'no_connection_data': 'No connection and no saved data yet',
      'offline_sign_in': "You're offline — please connect to the internet to sign in.",
      'offline_register': "You're offline — please connect to the internet to register.",
      'offline_reset_password': "You're offline — please connect to the internet to reset your password.",
      'offline_change_password': "You're offline — please connect to the internet to change your password.",
      'offline_account': "You're offline — account changes need a connection.",
      'offline_branches': "You're offline — connect to the internet to view our branches.",
      'offline_switch_branch': "You're offline — switching branches needs a connection.",
      'offline_manage_branches': "You're offline — managing branches needs a connection.",
      'offline_manage_coaches': "You're offline — managing coaches needs a connection.",
      'offline_load_chat': 'No saved messages yet — connect to the internet to load the chat.',
      'offline_pull_refresh': 'No saved data yet — connect to the internet and pull to refresh.',
      'offline_manage_reconnect': 'Managing needs a connection. Reconnect and try again.',
      'retry': 'Retry',
      'record_deleted': 'Record deleted',
      'copied_label': 'copied!',
      'coach_fallback': 'Coach',
      'unknown_author': 'Unknown',

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
      'welcome_title': 'مرحبًا بك في HFA!',
      'branch_count': 'لدينا فروع في القاهرة والجيزة!',
      'nearest_branch': 'أقرب فرع',
      'branch_name': 'الفرع الرئيسي - وسط البلد',
      'practice_time': 'مواعيد التمرين: من الإثنين إلى الجمعة، من ٤ إلى ٦ مساءً',
      'login': 'تسجيل الدخول',
      'register': 'ليس لديك حساب؟ سجّل الآن',
      'view_branches': 'استعرض فروعنا',
      'coach_login': 'دخول المدرب',
      'swimming_academy': 'أكاديمية السباحة',
      'fitness_academy': 'أكاديمية اللياقة البدنية',

      // Login
      'welcome_back': 'مرحبًا بعودتك',
      'sign_in_athlete': 'سجّل الدخول إلى حساب اللاعب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'enter_email': 'أدخل بريدك الإلكتروني',
      'enter_password': 'أدخل كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'sign_in': 'تسجيل الدخول',
      'no_account': 'ليس لديك حساب؟ ',
      'register_now': 'سجّل الآن',
      'logging_in': 'جارٍ تسجيل الدخول...',
      'fill_all_fields': 'يرجى ملء جميع الحقول',
      'athletes_only': 'تسجيل الدخول هنا متاح للاعبين فقط.',
      'login_failed': 'تعذر تسجيل الدخول',

      // Register
      'create_account': 'إنشاء حساب',
      'join_academy': 'انضم إلى أكاديميتنا',
      'full_name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'phone_optional': 'رقم الهاتف (اختياري)',
      'phone_verify_hint': 'يُنصح به بشدة — يستخدم المدرب رقم هاتفك للتحقق من هويتك واعتماد تسجيلك بسرعة. في حال عدم إدخال الرقم، قد يتأخر اعتماد التسجيل لحين التحقق من هويتك شخصيًا في الفرع.',
      'confirm_password': 'تأكيد كلمة المرور',
      'branch': 'الفرع',
      'select_branch': 'اختر فرعك',
      'submit_registration': 'إرسال طلب التسجيل',
      'registration_submitted': 'تم إرسال طلب التسجيل! سيقوم المدرب بمراجعته.',
      'successfully_registered': 'تم التسجيل بنجاح',
      'invalid_login': 'بيانات الدخول غير صحيحة',
      'ok': 'حسنًا',
      'passwords_no_match': 'كلمتا المرور غير متطابقتين.',
      'registration_info': 'سيراجع فريق التدريب طلب تسجيلك.',

      // Admin / Coach Login
      'coach_portal': 'بوابة المدرب',
      'access_dashboard': 'ادخل إلى لوحة تحكم المدرب',
      'coaches_only': 'هذه الصفحة متاحة للمدربين فقط.',

      // Head Coach
      'head_coach': 'المدرب الرئيسي',
      'head_coach_login': 'دخول المدرب الرئيسي',
      'head_coach_only': 'تسجيل الدخول هنا متاح للمدرب الرئيسي فقط.',
      'select_branch_manage': 'اختر فرعًا لإدارته',
      'manage_coaches': 'إدارة المدربين',
      'switching_branch': 'جارٍ تبديل الفرع...',
      'loading_branches': 'جارٍ تحميل الفروع...',
      'no_branches': 'لا توجد فروع.',
      'failed_switch': 'تعذر تبديل الفرع',

      // Pending
      'pending_approval': 'في انتظار الموافقة',
      'pending_message': 'طلب تسجيلك قيد المراجعة من المدرب.\nسنخطرك فور الموافقة عليه.',
      'registration_rejected': 'لم يتم قبول التسجيل',
      'registration_rejected_message': 'نأسف، لم يتم قبول طلب تسجيلك. يمكنك التسجيل مرة أخرى في أي وقت.',
      'logout': 'تسجيل الخروج',

      // Reset Password
      'reset_password': 'إعادة تعيين كلمة المرور',
      'forgot_desc': 'أدخل بريدك الإلكتروني وسنرسل لك رمز إعادة التعيين.',
      'email_address': 'البريد الإلكتروني',
      'send_reset': 'إرسال رمز إعادة التعيين',
      'reset_sent': 'تم إرسال الرمز!',
      'send_code': 'إرسال الرمز',
      'enter_reset_code': 'أدخل الرمز',
      'code_sent_to_email': 'أرسلنا رمزًا مكونًا من ٦ أرقام إلى',
      'code_expires_15': 'تنتهي صلاحية الرمز خلال ١٥ دقيقة',
      'verify_code': 'تأكيد الرمز',
      'resend_code': 'إعادة إرسال الرمز',
      'new_password_title': 'كلمة مرور جديدة',
      'new_password_desc': 'اختر كلمة مرور جديدة لحسابك',
      'password_reset_success': 'تمت إعادة تعيين كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول.',

      // Change Password
      'change_email': 'تغيير البريد الإلكتروني',
      'change_password': 'تغيير كلمة المرور',
      'current_password': 'كلمة المرور الحالية',
      'new_password': 'كلمة المرور الجديدة',
      'update_password': 'تحديث كلمة المرور',
      'password_changed': 'تم تغيير كلمة المرور بنجاح.',
      'password_failed': 'تعذر تغيير كلمة المرور.',

      // Dashboard (Athlete)
      'dashboard': 'لوحة التحكم',
      'weekly_attendance': 'الحضور الأسبوعي',
      'latest_chat': 'آخر محادثة',
      'gear_check': 'معدات اللياقة',
      'payment': 'الاشتراك',
      'status': 'الحالة',
      'paid': 'مدفوع',
      'late': 'متأخر',
      'pending': 'قيد الانتظار',
      'unknown': 'غير معروف',
      'loading': 'جارٍ التحميل...',
      'loading_dashboard': 'جارٍ تحميل لوحة التحكم...',
      'day': 'اليوم',
      'present': 'حاضر',
      'absent': 'غائب',

      // Chat
      'threads': 'المحادثات',
      'loading_threads': 'جارٍ تحميل المحادثات...',
      'no_threads': 'لا توجد محادثات',
      'no_messages': 'لا توجد رسائل بعد',

      // Gear
      'gear_update': 'تحديث معدات اللياقة',
      'gear_subtitle': 'آخر معدات اللياقة المطلوبة من مدربك',
      'loading_gear': 'جارٍ تحميل معدات اللياقة...',

      // Profile
      'attendance_tracker': 'الحضور',
      'view_calendar': 'عرض التقويم',
      'measurements': 'القياسات',
      'save_measurements': 'حفظ القياسات',
      'edit': 'تعديل',
      'swim_events': 'سباقات السباحة',
      'add_event': 'إضافة سباق',
      'save_events': 'حفظ السباقات',
      'event_name': 'السباق',
      'time': 'الزمن',
      'height': 'الطول (سم)',
      'weight': 'الوزن (كجم)',
      'arm': 'الذراع (سم)',
      'leg': 'الساق (سم)',
      'fat': 'نسبة الدهون %',
      'muscle': 'نسبة العضلات %',
      'saved': 'تم الحفظ!',
      'save_failed': 'تعذر الحفظ',

      // Coach Home
      'coach_dashboard': 'لوحة تحكم المدرب',
      'quick_actions': 'إجراءات سريعة',
      'registration_requests': 'طلبات التسجيل',
      'payment_tracking': 'متابعة الاشتراكات',
      'attendance': 'الحضور',

      // Coach Chat
      'branch_chat': 'محادثة الفرع',
      'messages': 'رسائل',
      'type_message': 'اكتب رسالتك...',

      // Coach Gear
      'weekly_gear_update': 'تحديث معدات اللياقة',
      'enter_gear': 'اكتب معدات اللياقة المطلوبة من اللاعبين...',
      'save_gear': 'حفظ معدات اللياقة',
      'saving': 'جارٍ الحفظ...',
      'gear_saved': 'تم حفظ معدات اللياقة!',
      'gear_failed': 'تعذر نشر معدات اللياقة.',

      // Coach Profile
      'coach_profile': 'الملف الشخصي للمدرب',
      'settings': 'الإعدادات',
      'edit_profile': 'تعديل الملف الشخصي',
      'attendance_summary': 'ملخص حضور الفرع',

      // Edit Profile
      'name': 'الاسم',
      'save_changes': 'حفظ التغييرات',
      'profile_updated': 'تم تحديث الملف الشخصي.',
      'profile_failed': 'تعذر تحديث الملف الشخصي.',

      // Registration Requests
      'pending_requests': 'طلبات التسجيل',
      'no_requests': 'لا توجد طلبات معلقة',
      'approve': 'قبول',
      'reject': 'رفض',
      'reject_confirm': 'رفض الطلب؟',
      'reject_desc': 'سيتم رفض طلب التسجيل نهائيًا.',
      'cancel': 'إلغاء',
      'athlete_approved': 'تم قبول اللاعب',
      'request_rejected': 'تم رفض الطلب',

      // Payment
      'search_athlete': 'ابحث عن لاعب...',
      'no_athletes': 'لا يوجد لاعبون.',

      // Attendance
      'weekly_attendance_title': 'الحضور الأسبوعي',
      'loading_attendance': 'جارٍ تحميل الحضور...',
      'no_branch': 'لم يتم تعيين فرع بعد',

      // Attendance Summary
      'attendance_summary_title': 'ملخص الحضور',
      'loading_summary': 'جارٍ تحميل الملخص...',

      // Manage Coaches
      'add_coach': 'إضافة مدرب',
      'no_coaches': 'لا يوجد مدربون بعد',
      'tap_add': 'اضغط على + للإضافة',
      'create_coach': 'إنشاء مدرب',
      'edit_coach': 'تعديل بيانات المدرب',
      'delete_coach': 'حذف المدرب',
      'delete_confirm': 'هل أنت متأكد من حذف',
      'delete': 'حذف',
      'create': 'إنشاء',
      'save': 'حفظ',
      'reset': 'إعادة تعيين',
      'reset_password_for': 'إعادة تعيين كلمة المرور لـ',
      'coach_created': 'تم إنشاء المدرب',
      'coach_updated': 'تم تحديث بيانات المدرب',
      'coach_deleted': 'تم حذف المدرب',
      'password_reset_done': 'تمت إعادة تعيين كلمة المرور',
      'loading_coaches': 'جارٍ تحميل المدربين...',

      // Language
      'language': 'اللغة',
      'language_current': 'العربية',

      // Nav
      'home': 'الرئيسية',
      'chat': 'المحادثات',
      'gear': 'الأدوات',
      'payments': 'المدفوعات',
      'profile': 'الملف الشخصي',
      'athletes': 'اللاعبون',
      'threads_nav': 'المحادثات',

      // Extra UI
      'hi': 'أهلًا',
      'switch_text': 'تبديل',
      'view_full_calendar': 'عرض تقويم الحضور الكامل',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'new_email': 'البريد الإلكتروني الجديد',
      'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
      'update': 'تحديث',
      'email_updated': 'تم تحديث البريد الإلكتروني بنجاح',
      'email_update_failed': 'تعذر تحديث البريد الإلكتروني',
      'measurements_saved': 'تم حفظ القياسات!',
      'events_saved': 'تم حفظ السباقات!',
      'no_payment_records': 'لا توجد سجلات دفع بعد',
      'branch_label': 'الفرع',
      'no_payment': 'لم يتم الدفع',
      'athlete': 'لاعب',
      'monthly_attendance': 'الحضور الشهري',
      'body_measurements': 'قياسات الجسم',
      'swim_events_times': 'سباقات السباحة والأزمنة',
      'no_measurements': 'لم تُسجل أي قياسات بعد',
      'no_swim_events': 'لم تُسجل أي سباقات بعد',
      'rate': 'المعدل',
      'of_sessions': 'حصة',
      'new_coach': 'مدرب جديد',
      'password_auto_gen': 'سيتم إنشاء كلمة المرور تلقائيًا',
      'name_email_required': 'الاسم والبريد الإلكتروني مطلوبان',
      'failed_to_load': 'تعذر تحميل البيانات',
      'coach_credentials': 'بيانات دخول المدرب',
      'share_credentials': 'شارك بيانات الدخول هذه مع المدرب',
      'copy_all': 'نسخ الكل',
      'credentials_copied': 'تم نسخ بيانات الدخول!',
      'done': 'تم',
      'assign_branch': 'تعيين الفرع',
      'branch_assigned': 'تم تعيين الفرع',
      'remove_permanently': 'نهائيًا؟',
      'failed_generic': 'حدث خطأ',
      'failed_create_coach': 'تعذر إنشاء المدرب',
      'coaches': 'المدربون',
      'add_first_coach': 'أضف أول مدرب',
      'credentials': 'بيانات الدخول',
      'unassigned': 'بدون فرع',
      'copied': 'تم النسخ!',
      'switch_branch': 'تبديل الفرع',
      'approved_text': 'تم القبول!',
      'rejected_text': 'تم الرفض',
      'all_caught_up': 'لا توجد طلبات جديدة!',
      'failed_to_approve': 'تعذر القبول',
      'failed_to_reject': 'تعذر الرفض',
      'failed_load_sessions': 'تعذر تحميل مواعيد الحصص',
      'no_gear_posted': 'لم يتم نشر معدات اللياقة بعد.',
      'error_loading_gear': 'حدث خطأ أثناء تحميل معدات اللياقة.',
      'no_gear_updates': 'لا توجد تحديثات لمعدات اللياقة.',
      'no_posts': 'لا توجد منشورات بعد.',
      'no_threads_available': 'لا توجد محادثات.',
      'message_hint': 'اكتب رسالة',
      'confirm_password_label': 'تأكيد كلمة المرور',
      'created_text': 'تم الإنشاء!',
      'server_error': 'خطأ في الخادم',

      // Branches
      'our_branches': 'فروعنا',
      'practice_schedule': 'مواعيد التمرين',
      'branch_tour': 'جولة في الفرع',
      'watch_video': 'مشاهدة الفيديو',
      'ready_to_join': 'مستعد للانضمام إلى HFA؟',
      'no_branches_found': 'لا توجد فروع',
      'failed_load_branches': 'تعذر تحميل الفروع',

      // Manage Branches (head coach)
      'manage_branches': 'إدارة الفروع',
      'add_branch': 'إضافة فرع',
      'edit_branch': 'تعديل الفرع',
      'delete_branch': 'حذف الفرع',
      'delete_branch_confirm': 'هل أنت متأكد من حذف هذا الفرع؟',
      'branch_name_label': 'اسم الفرع',
      'address': 'العنوان',
      'whatsapp': 'واتساب',
      'video_url_label': 'رابط الفيديو',
      'branch_saved': 'تم حفظ الفرع',
      'branch_deleted': 'تم حذف الفرع',
      'practice_schedule_helper': 'يظهر كل سطر أو عنصر مفصول بفاصلة كنقطة مستقلة في الصفحة العامة',

      // Health History
      'health_history': 'السجل الصحي',
      'health_history_desc': 'تابع سجلاتك الطبية وحالاتك الصحية',
      'no_health_records': 'لا توجد سجلات صحية بعد',
      'tap_add_record': 'اضغط على + لإضافة أول سجل',
      'new_health_record': 'سجل صحي جديد',
      'record_name': 'اسم الحالة',
      'record_name_hint': 'مثال: إصابة في الكتف، ربو...',
      'notes_label': 'ملاحظات',
      'notes_hint': 'صف الحالة والعلاج وغير ذلك...',
      'attachments': 'الصور',
      'max_2_photos': 'حتى صورتين (تقارير طبية، أشعة...)',
      'save_record': 'حفظ السجل',
      'record_created': 'تم حفظ السجل الصحي!',
      'enter_record_title': 'يرجى إدخال اسم الحالة',
      'delete_health_record_confirm': 'هل أنت متأكد من حذف هذا السجل الصحي؟',

      // Coach Notes
      'coach_notes': 'ملاحظات المدرب',
      'add_note': 'إضافة ملاحظة',
      'no_coach_notes': 'لا توجد ملاحظات بعد',
      'coach_note_hint': 'اكتب ملاحظاتك عن هذا السباح...',
      'add_coach_note': 'إضافة ملاحظة',

      // Parent Access
      'parent_access': 'دخول ولي الأمر',
      'parent_access_desc': 'اسمح لولي أمرك بالاطلاع على حسابك',
      'generate_code': 'إنشاء رمز الدخول',
      'your_code': 'رمز الدخول الخاص بك',
      'code_expires': 'صالح لمدة ٧٢ ساعة',
      'copy_code': 'نسخ الرمز',
      'new_code': 'رمز جديد',
      'parent_login_desc': 'أدخل الرمز المكون من ٦ خانات الذي شاركه اللاعب معك للدخول إلى حسابه.',
      'access_code': 'رمز الدخول',
      'enter_code': 'يرجى إدخال الرمز',
      'invalid_code': 'الرمز غير صالح أو منتهي الصلاحية',

      // Legal & Account
      'delete_account': 'حذف الحساب',
      'delete_account_desc': 'حذف حسابك وجميع بياناتك نهائيًا',
      'delete_account_confirm': 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      'delete_account_password': 'أدخل كلمة المرور للتأكيد',
      'account_deleted': 'تم حذف الحساب بنجاح',
      'privacy_policy': 'سياسة الخصوصية',
      'terms_of_service': 'شروط الخدمة',
      'agree_terms_prefix': 'بالتسجيل، أنت توافق على ',
      'and_word': ' و ',

      // Offline
      'no_connection': 'لا يوجد اتصال بالإنترنت',
      'no_connection_data': 'لا يوجد اتصال ولا توجد بيانات محفوظة بعد',
      'offline_sign_in': 'أنت غير متصل بالإنترنت — يرجى الاتصال لتسجيل الدخول.',
      'offline_register': 'أنت غير متصل بالإنترنت — يرجى الاتصال لإتمام التسجيل.',
      'offline_reset_password': 'أنت غير متصل بالإنترنت — يرجى الاتصال لإعادة تعيين كلمة المرور.',
      'offline_change_password': 'أنت غير متصل بالإنترنت — يرجى الاتصال لتغيير كلمة المرور.',
      'offline_account': 'أنت غير متصل بالإنترنت — تغييرات الحساب تتطلب اتصالًا بالإنترنت.',
      'offline_branches': 'أنت غير متصل بالإنترنت — اتصل بالإنترنت لعرض فروعنا.',
      'offline_switch_branch': 'أنت غير متصل بالإنترنت — تبديل الفرع يتطلب اتصالًا بالإنترنت.',
      'offline_manage_branches': 'أنت غير متصل بالإنترنت — إدارة الفروع تتطلب اتصالًا بالإنترنت.',
      'offline_manage_coaches': 'أنت غير متصل بالإنترنت — إدارة المدربين تتطلب اتصالًا بالإنترنت.',
      'offline_load_chat': 'لا توجد رسائل محفوظة بعد — اتصل بالإنترنت لتحميل المحادثة.',
      'offline_pull_refresh': 'لا توجد بيانات محفوظة بعد — اتصل بالإنترنت واسحب للتحديث.',
      'offline_manage_reconnect': 'الإدارة تتطلب اتصالًا بالإنترنت. أعد الاتصال وحاول مرة أخرى.',
      'retry': 'إعادة المحاولة',
      'record_deleted': 'تم حذف السجل',
      'copied_label': 'تم النسخ!',
      'coach_fallback': 'مدرب',
      'unknown_author': 'غير معروف',

      // Notifications
      'notifications': 'الإشعارات',
      'no_notifications': 'لا توجد إشعارات بعد',
      'no_notifications_desc': 'ستصلك الإشعارات عندما ينشر مدربك تحديثات جديدة',
      'mark_all_read': 'تحديد الكل كمقروء',
      'just_now': 'الآن',
      'minutes_ago': 'د مضت',
      'hours_ago': 'س مضت',
      'days_ago': 'ي مضت',
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
    notifyListeners();
  }

  void toggleLocale() async {
    _locale = _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', _locale.languageCode);
    notifyListeners();
    // Re-register device token so push notifications use the new language
    PushNotificationService.forceReRegister();
  }

  void setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale.languageCode);
    notifyListeners();
    // Re-register device token so push notifications use the new language
    PushNotificationService.forceReRegister();
  }
}
