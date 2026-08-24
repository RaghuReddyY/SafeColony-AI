
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/marketplace.dart';

class MarketplaceService {
  Future<List<MarketplaceEvent>> events() async {
    final r=await ApiClient.dio.get('/marketplace/events');
    return (r.data as List).map((e)=>MarketplaceEvent.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<List<MarketplaceVendor>> vendors() async {
    final r=await ApiClient.dio.get('/marketplace/vendors');
    return (r.data as List).map((e)=>MarketplaceVendor.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<MarketplaceVendor> createVendor({required String name,required String category,String? phone,int? userId}) async {
    final r=await ApiClient.dio.post('/marketplace/vendors',data:{'name':name,'category':category,'phone':phone,'user_id':userId});
    return MarketplaceVendor.fromJson(Map<String,dynamic>.from(r.data));
  }

  Future<MarketplaceVendor> createVendorAccount({required String name, required String category, String? phone, String? notes, required String fullName, required String email, required String password}) async {
    final r=await ApiClient.dio.post('/marketplace/vendor-accounts',data:{'name':name,'category':category,'phone':phone,'notes':notes,'full_name':fullName,'email':email,'password':password});
    return MarketplaceVendor.fromJson(Map<String,dynamic>.from(r.data));
  }

  Future<MarketplaceEvent> createEvent({required String title,required String category,required String eventType,int? vendorId,String? description,DateTime? cutoffAt,DateTime? scheduledFor}) async {
    final r=await ApiClient.dio.post('/marketplace/events',data:{
      'title':title,'category':category,'event_type':eventType,'vendor_id':vendorId,'description':description,
      'cutoff_at':cutoffAt?.toIso8601String(),'scheduled_for':scheduledFor?.toIso8601String(),
    });
    return MarketplaceEvent.fromJson(Map<String,dynamic>.from(r.data));
  }
  Future<MarketplaceOrder> placeOrder(int eventId,List<MarketplaceItem> items,{String? notes,String? serviceSlot,String? paymentReference}) async {
    final r=await ApiClient.dio.post('/marketplace/events/$eventId/orders',data:{
      'items':items.map((i)=>{'name':i.name,'quantity':i.quantity,'unit':i.unit,'unit_price':i.unitPrice}).toList(),
      'delivery_mode':'COMMUNITY_DROP','notes':notes,'service_slot':serviceSlot,'payment_reference':paymentReference,
    });
    return MarketplaceOrder.fromJson(Map<String,dynamic>.from(r.data));
  }
  Future<List<MarketplaceOrder>> myOrders() async {
    final r=await ApiClient.dio.get('/marketplace/my-orders');
    return (r.data as List).map((e)=>MarketplaceOrder.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<VendorDashboard> vendorDashboard() async {
    final r=await ApiClient.dio.get('/marketplace/vendor/dashboard');
    return VendorDashboard.fromJson(Map<String,dynamic>.from(r.data));
  }
  Future<List<MarketplaceEvent>> vendorEvents() async {
    final r=await ApiClient.dio.get('/marketplace/vendor/events');
    return (r.data as List).map((e)=>MarketplaceEvent.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<MarketplaceAggregate> vendorAggregate(int id) async {
    final r=await ApiClient.dio.get('/marketplace/vendor/events/$id/aggregate');
    return MarketplaceAggregate.fromJson(Map<String,dynamic>.from(r.data));
  }
  Future<void> updateVendorEventStatus(int id,String status) async {
    await ApiClient.dio.patch('/marketplace/vendor/events/$id/status',data:{'status':status});
  }
  Future<List<VendorOffer>> vendorOffers() async {
    final r=await ApiClient.dio.get('/marketplace/vendor/offers');
    return (r.data as List).map((e)=>VendorOffer.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> createVendorOffer({int? eventId,required String title,String? description,double discountPercent=0,int minOrders=1}) async {
    await ApiClient.dio.post('/marketplace/vendor/offers',data:{'event_id':eventId,'title':title,'description':description,'discount_percent':discountPercent,'min_orders':minOrders});
  }
  Future<List<MarketplaceOrder>> vendorOrders() async {
    final r=await ApiClient.dio.get('/marketplace/vendor/orders');
    return (r.data as List).map((e)=>MarketplaceOrder.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> updateVendorOrder(int id,String status) async {
    await ApiClient.dio.patch('/marketplace/vendor/orders/$id',queryParameters:{'status':status});
  }
  Future<List<MarketplaceOrder>> adminOrders({int? eventId}) async {
    final r=await ApiClient.dio.get('/marketplace/orders', queryParameters: eventId == null ? null : {'event_id':eventId});
    return (r.data as List).map((e)=>MarketplaceOrder.fromJson(Map<String,dynamic>.from(e))).toList();
  }

  Future<MarketplaceEvent> updateEventStatus(int id,String status) async {
    final r=await ApiClient.dio.patch('/marketplace/events/$id/status',data:{'status':status});
    return MarketplaceEvent.fromJson(Map<String,dynamic>.from(r.data));
  }

  Future<MarketplaceAggregate> aggregate(int id) async {
    final r=await ApiClient.dio.get('/marketplace/events/$id/aggregate');
    return MarketplaceAggregate.fromJson(Map<String,dynamic>.from(r.data));
  }


  Future<List<ServiceRequest>> vendorServiceRequests() async {
    final r=await ApiClient.dio.get('/super-app/vendor/service-requests');
    return (r.data as List).map((e)=>ServiceRequest.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> updateVendorServiceRequest(int id,String status,{double? quote}) async {
    await ApiClient.dio.patch('/super-app/vendor/service-requests/$id',data:{'status':status,'quoted_amount':quote});
  }

}