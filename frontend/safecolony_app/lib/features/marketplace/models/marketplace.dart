import '../../../core/utils/api_date_time.dart';

class MarketplaceVendor {
  final int id;
  final String name;
  final String category;
  final String? phone;
  final String? notes;
  final bool isActive;
  final int? userId;
  final String? email;
  final String? userFullName;
  MarketplaceVendor({required this.id, required this.name, required this.category, this.phone, this.notes, required this.isActive, this.userId, this.email, this.userFullName});
  factory MarketplaceVendor.fromJson(Map<String,dynamic> j)=>MarketplaceVendor(
    id:(j['id'] as num).toInt(), name:j['name']?.toString()??'', category:j['category']?.toString()??'',
    phone:j['phone']?.toString(), notes:j['notes']?.toString(), isActive:j['is_active'] != false,
    userId:(j['user_id'] as num?)?.toInt(),
    email:j['email']?.toString(), userFullName:j['user_full_name']?.toString(),
  );
}

class MarketplaceEvent {
  final int id; final String title, category, eventType, deliveryMode, status;
  final String? description, vendorName; final int? vendorId, orderCount, apartmentCount;
  final DateTime? cutoffAt, scheduledFor;
  MarketplaceEvent({required this.id,required this.title,required this.category,required this.eventType,required this.deliveryMode,required this.status,this.description,this.vendorName,this.vendorId,this.orderCount,this.apartmentCount,this.cutoffAt,this.scheduledFor});
  factory MarketplaceEvent.fromJson(Map<String,dynamic> j)=>MarketplaceEvent(
    id:(j['id'] as num).toInt(), title:j['title']?.toString()??'', category:j['category']?.toString()??'',
    eventType:j['event_type']?.toString()??'PRODUCT', deliveryMode:j['delivery_mode']?.toString()??'COMMUNITY_DROP',
    status:j['status']?.toString()??'OPEN', description:j['description']?.toString(), vendorName:j['vendor_name']?.toString(),
    vendorId:(j['vendor_id'] as num?)?.toInt(), orderCount:(j['order_count'] as num?)?.toInt(), apartmentCount:(j['apartment_count'] as num?)?.toInt(),
    cutoffAt:ApiDateTime.tryParse(j['cutoff_at']), scheduledFor:ApiDateTime.tryParse(j['scheduled_for']),
  );
}

class MarketplaceItem {
  final String name, unit; final double quantity, unitPrice;
  MarketplaceItem({required this.name,required this.unit,required this.quantity,required this.unitPrice});
  factory MarketplaceItem.fromJson(Map<String,dynamic> j)=>MarketplaceItem(
    name:j['name']?.toString()??'', unit:j['unit']?.toString()??'unit',
    quantity:double.tryParse(j['quantity']?.toString()??'')??0, unitPrice:double.tryParse(j['unit_price']?.toString()??'')??0,
  );
}

class MarketplaceOrder {
  final int id,eventId; final String eventTitle,residentName,status,paymentStatus,deliveryMode; final double totalAmount; final String? notes; final String? serviceSlot; final String? paymentReference; final List<MarketplaceItem> items;
  MarketplaceOrder({required this.id,required this.eventId,required this.eventTitle,required this.residentName,required this.status,required this.paymentStatus,required this.deliveryMode,required this.totalAmount,this.notes,this.serviceSlot,this.paymentReference,required this.items});
  factory MarketplaceOrder.fromJson(Map<String,dynamic> j)=>MarketplaceOrder(
    id:(j['id'] as num).toInt(),eventId:(j['event_id'] as num).toInt(),eventTitle:j['event_title']?.toString()??'',
    residentName:j['resident_name']?.toString()??'',status:j['status']?.toString()??'',paymentStatus:j['payment_status']?.toString()??'',
    deliveryMode:j['delivery_mode']?.toString()??'',totalAmount:double.tryParse(j['total_amount']?.toString()??'')??0,
    notes:j['notes']?.toString(),serviceSlot:j['service_slot']?.toString(),paymentReference:j['payment_reference']?.toString(),items:(j['items'] as List? ?? const []).map((e)=>MarketplaceItem.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}

class MarketplaceAggregate {
  final int eventId, apartmentCount, orderCount; final String eventTitle; final double totalAmount; final List<MarketplaceAggregateItem> items;
  MarketplaceAggregate({required this.eventId,required this.apartmentCount,required this.orderCount,required this.eventTitle,required this.totalAmount,required this.items});
  factory MarketplaceAggregate.fromJson(Map<String,dynamic> j)=>MarketplaceAggregate(
    eventId:(j['event_id'] as num).toInt(), apartmentCount:(j['apartment_count'] as num?)?.toInt()??0,
    orderCount:(j['order_count'] as num?)?.toInt()??0,eventTitle:j['event_title']?.toString()??'',
    totalAmount:double.tryParse(j['total_amount']?.toString()??'')??0,
    items:(j['items'] as List? ?? const []).map((e)=>MarketplaceAggregateItem.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}
class MarketplaceAggregateItem {
  final String name,unit; final double quantity; final int orderCount;
  MarketplaceAggregateItem({required this.name,required this.unit,required this.quantity,required this.orderCount});
  factory MarketplaceAggregateItem.fromJson(Map<String,dynamic> j)=>MarketplaceAggregateItem(
    name:j['name']?.toString()??'',unit:j['unit']?.toString()??'',quantity:double.tryParse(j['quantity']?.toString()??'')??0,orderCount:(j['order_count'] as num?)?.toInt()??0,
  );
}


class VendorDashboard {
  final int vendorId, openEvents, upcomingEvents, totalOrders, pendingOrders, readyOrders, deliveredOrders, ratingCount;
  final String vendorName, category; final String? phone; final bool active; final double totalSales, averageRating;
  VendorDashboard({required this.vendorId,required this.vendorName,required this.category,this.phone,required this.active,required this.openEvents,required this.upcomingEvents,required this.totalOrders,required this.pendingOrders,required this.readyOrders,required this.deliveredOrders,required this.totalSales,required this.averageRating,required this.ratingCount});
  factory VendorDashboard.fromJson(Map<String,dynamic> j)=>VendorDashboard(vendorId:(j['vendor_id'] as num).toInt(),vendorName:j['vendor_name']?.toString()??'',category:j['category']?.toString()??'',phone:j['phone']?.toString(),active:j['active']!=false,openEvents:(j['open_events'] as num?)?.toInt()??0,upcomingEvents:(j['upcoming_events'] as num?)?.toInt()??0,totalOrders:(j['total_orders'] as num?)?.toInt()??0,pendingOrders:(j['pending_orders'] as num?)?.toInt()??0,readyOrders:(j['ready_orders'] as num?)?.toInt()??0,deliveredOrders:(j['delivered_orders'] as num?)?.toInt()??0,totalSales:double.tryParse(j['total_sales']?.toString()??'')??0,averageRating:double.tryParse(j['average_rating']?.toString()??'')??0,ratingCount:(j['rating_count'] as num?)?.toInt()??0);
}


class VendorOffer {
  final int id, vendorId, minOrders; final int? eventId; final String title; final String? description; final double discountPercent;
  VendorOffer({required this.id,required this.vendorId,this.eventId,required this.title,this.description,required this.discountPercent,required this.minOrders});
  factory VendorOffer.fromJson(Map<String,dynamic> j)=>VendorOffer(id:(j['id'] as num).toInt(),vendorId:(j['vendor_id'] as num).toInt(),eventId:(j['event_id'] as num?)?.toInt(),title:j['title']?.toString()??'',description:j['description']?.toString(),discountPercent:double.tryParse(j['discount_percent']?.toString()??'')??0,minOrders:(j['min_orders'] as num?)?.toInt()??1);
}


class ServiceRequest {
  final int id; final String category,title,status; final String? description,preferredSlot,providerName,vendorName; final double? quotedAmount;
  ServiceRequest({required this.id,required this.category,required this.title,required this.status,this.description,this.preferredSlot,this.providerName,this.vendorName,this.quotedAmount});
  factory ServiceRequest.fromJson(Map<String,dynamic> j)=>ServiceRequest(id:(j['id'] as num).toInt(),category:j['category']?.toString()??'',title:j['title']?.toString()??'',status:j['status']?.toString()??'',description:j['description']?.toString(),preferredSlot:j['preferred_slot']?.toString(),providerName:j['provider_name']?.toString(),vendorName:j['vendor_name']?.toString(),quotedAmount:double.tryParse(j['quoted_amount']?.toString()??''));
}
