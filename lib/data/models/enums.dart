enum UserRole { teacher, assistant, student, parent, platformAdmin }

enum SubscriptionPlan { basic, pro, premium }

enum SubscriptionStatus { active, trial, expired }

enum StaffType { assistant, supervisor }

enum Permission { attendance, students, payments, sheets, grades, accounts, announcements }

enum GroupType { public, private }

enum AttendanceStatus { present, late, absentExcused, absent }

enum AttendanceMethod { qr, manual }

enum PaymentMethod { cash, vodafoneCash, instaPay, bankTransfer, fawry, other }

enum ExpenseCategory { rent, printing, salaries, other }

enum AssessmentType { homework, exam }

enum RequestType { absence, changeGroup, other }

enum RequestStatus { pending, approved, rejected }

enum ComplaintKind { complaint, warning }

enum NotificationType { attendance, payment, announcement, request, complaint, general }
