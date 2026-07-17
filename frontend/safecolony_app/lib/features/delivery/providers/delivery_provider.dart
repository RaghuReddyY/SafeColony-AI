import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery.dart';
import '../services/delivery_service.dart';

final deliveryProvider =
    Provider(
  (ref) => DeliveryProvider(),
);

class DeliveryProvider {

  final DeliveryService _service =
      DeliveryService();

  Future<List<Delivery>>
      loadDeliveries() {

    return _service.getDeliveries();
  }
}