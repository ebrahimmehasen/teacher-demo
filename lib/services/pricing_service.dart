import '../data/models/models.dart';

/// Rule 1: private group price, else grade public price; then discount; exempt ⇒ 0.
abstract final class PricingService {
  static double basePrice(Group group, Grade grade) =>
      group.isPrivate ? (group.price ?? grade.publicPrice) : grade.publicPrice;

  static double monthlyPrice({
    required Enrollment enrollment,
    required Group group,
    required Grade grade,
  }) {
    if (enrollment.isExempt) return 0;
    final base = basePrice(group, grade);
    return (base * (100 - enrollment.discountPercent) / 100).roundToDouble();
  }
}
