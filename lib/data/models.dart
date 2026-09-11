import 'package:flutter/material.dart';

int _int(dynamic v, [int fallback = 0]) => v is int
    ? v
    : v is num
    ? v.toInt()
    : int.tryParse('$v') ?? fallback;
double _dbl(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
DateTime _date(dynamic v) => v == null
    ? DateTime.now()
    : (DateTime.tryParse('$v') ?? DateTime.now()).toLocal();

/// Server amounts are in kobo; the UI works in whole naira.
int koboToNaira(dynamic kobo) => (_int(kobo) / 100).round();
int nairaToKobo(int naira) => naira * 100;

/// Maps real Lagos coordinates onto the stylised 0..1 map canvas.
/// Bounding box roughly Ojo (west) → Lekki/Ajah (east), Ikeja (north) → Victoria Island (south).
Offset projectToCanvas(double lat, double lng) {
  const minLat = 6.40, maxLat = 6.70, minLng = 3.20, maxLng = 3.70;
  final x = ((lng - minLng) / (maxLng - minLng)).clamp(0.05, 0.95);
  final y = (1 - (lat - minLat) / (maxLat - minLat)).clamp(0.05, 0.95);
  return Offset(x, y);
}

/// Enums mirror the server's Drizzle schema so the API plugs in without mapping.
enum VehicleCategory {
  economy('Economy', 4, Icons.directions_car_rounded),
  comfort('Comfort', 4, Icons.directions_car_filled_rounded),
  premium('Premium', 4, Icons.local_taxi_rounded),
  xl('XL', 6, Icons.airport_shuttle_rounded);

  const VehicleCategory(this.label, this.seats, this.icon);
  final String label;
  final int seats;
  final IconData icon;

  /// Wire value (`economy` …).
  String get wire => name;
  static VehicleCategory fromWire(String? v) => VehicleCategory.values.firstWhere(
    (c) => c.name == v,
    orElse: () => VehicleCategory.economy,
  );
}

enum TripStatus {
  requested,
  matched,
  driverArriving,
  driverArrived,
  inProgress,
  completed,
  cancelled;

  static TripStatus fromWire(String? v) => switch (v) {
    'matched' => TripStatus.matched,
    'driver_arriving' => TripStatus.driverArriving,
    'driver_arrived' => TripStatus.driverArrived,
    'in_progress' => TripStatus.inProgress,
    'completed' => TripStatus.completed,
    'cancelled' => TripStatus.cancelled,
    _ => TripStatus.requested,
  };
}

enum TripMode {
  immediate,
  scheduled,
  negotiated;

  static TripMode fromWire(String? v) => TripMode.values.firstWhere(
    (m) => m.name == v,
    orElse: () => TripMode.immediate,
  );
}

enum PaymentMethodType {
  card,
  wallet,
  cash,
  bankTransfer;

  String get wire => this == PaymentMethodType.bankTransfer ? 'bank_transfer' : name;
  static PaymentMethodType fromWire(String? v) => switch (v) {
    'wallet' => PaymentMethodType.wallet,
    'cash' => PaymentMethodType.cash,
    'bank_transfer' => PaymentMethodType.bankTransfer,
    _ => PaymentMethodType.card,
  };
}

enum CaseStatus {
  open,
  pendingUser,
  pendingAgent,
  escalated,
  resolved,
  closed;

  static CaseStatus fromWire(String? v) => switch (v) {
    'pending_user' => CaseStatus.pendingUser,
    'pending_agent' => CaseStatus.pendingAgent,
    'escalated' => CaseStatus.escalated,
    'resolved' => CaseStatus.resolved,
    'closed' => CaseStatus.closed,
    _ => CaseStatus.open,
  };
}

class Place {
  const Place({
    required this.name,
    required this.address,
    this.icon = Icons.place_outlined,
    this.distanceKm,
    this.at,
    this.id,
    this.lat,
    this.lng,
    this.label,
  });
  final String? id;
  final String name;
  final String address;
  final IconData icon;
  final double? distanceKm;
  final double? lat;
  final double? lng;

  /// `home` | `work` | `other` for saved places.
  final String? label;

  /// Normalised map coordinate (0..1) for the stylised map.
  final Offset? at;

  bool get hasCoords => lat != null && lng != null;

  /// Geocoder result: `{ name, address, coordinates: { lat, lng } }`.
  factory Place.fromGeocode(Map<String, dynamic> j) {
    final c = (j['coordinates'] as Map?) ?? const {};
    final lat = _dbl(c['lat']);
    final lng = _dbl(c['lng']);
    return Place(
      name: '${j['name'] ?? j['address'] ?? ''}',
      address: '${j['address'] ?? ''}',
      lat: lat,
      lng: lng,
      at: projectToCanvas(lat, lng),
    );
  }

  /// Saved place row: `{ id, label, name, address, lat, lng }`.
  factory Place.fromSaved(Map<String, dynamic> j) {
    final label = '${j['label'] ?? 'other'}';
    final lat = _dbl(j['lat']);
    final lng = _dbl(j['lng']);
    return Place(
      id: '${j['id']}',
      name: '${j['name'] ?? ''}',
      address: '${j['address'] ?? ''}',
      lat: lat,
      lng: lng,
      label: label,
      icon: switch (label) {
        'home' => Icons.home_rounded,
        'work' => Icons.work_rounded,
        _ => Icons.star_rounded,
      },
      at: projectToCanvas(lat, lng),
    );
  }

  Place copyWith({String? name, String? address, IconData? icon, Offset? at, String? label}) =>
      Place(
        id: id,
        name: name ?? this.name,
        address: address ?? this.address,
        icon: icon ?? this.icon,
        distanceKm: distanceKm,
        lat: lat,
        lng: lng,
        label: label ?? this.label,
        at: at ?? this.at,
      );
}

class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.trips,
    required this.vehicle,
    required this.memberSince,
    this.bio,
    this.topDriver = false,
    this.phone,
  });
  final String id;
  final String name;
  final double rating;
  final int trips;
  final Vehicle vehicle;
  final int memberSince;
  final String? bio;
  final bool topDriver;
  final String? phone;

  String get firstName => name.split(' ').first;

  /// Trip payload `driver` + `vehicle` objects from GET /rides/:id.
  factory Driver.fromTripJson(Map<String, dynamic> d, Map<String, dynamic>? v) {
    return Driver(
      id: '${d['id']}',
      name: '${d['name'] ?? 'NaijaMove driver'}',
      phone: d['phone']?.toString(),
      rating: _dbl(d['rating'], 5),
      trips: _int(d['totalTrips']),
      vehicle: v == null
          ? const Vehicle(
              make: 'Vehicle',
              model: '',
              year: 0,
              colour: '',
              plate: '—',
              category: VehicleCategory.economy,
            )
          : Vehicle(
              make: '${v['make'] ?? ''}',
              model: '${v['model'] ?? ''}',
              year: _int(v['year']),
              colour: '${v['color'] ?? v['colour'] ?? ''}',
              plate: '${v['plate'] ?? '—'}',
              category: VehicleCategory.fromWire('${v['category']}'),
            ),
      memberSince: DateTime.now().year,
    );
  }
}

class Vehicle {
  const Vehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.colour,
    required this.plate,
    required this.category,
  });
  final String make;
  final String model;
  final int year;
  final String colour;
  final String plate;
  final VehicleCategory category;
  String get description => '$colour $make $model'.trim();
}

class FareQuote {
  const FareQuote({
    required this.category,
    required this.min,
    required this.max,
    required this.etaMin,
    this.surge,
    this.quoteId,
    this.breakdown = const [],
    this.expiresAt,
  });
  final VehicleCategory category;
  final int min;
  final int max;
  final int etaMin;
  final double? surge;

  /// Server quote id — required to create a trip.
  final String? quoteId;

  /// Itemised (label, naira) rows from the server breakdown.
  final List<(String, int)> breakdown;
  final DateTime? expiresAt;

  int get estimate => ((min + max) / 2).round();
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// POST /pricing/quote → `{ quoteId, estimatedFareKobo, breakdown: {...}, expiresAt }`.
  factory FareQuote.fromJson(Map<String, dynamic> j, VehicleCategory category, {int etaMin = 4}) {
    final b = (j['breakdown'] as Map?) ?? const {};
    final est = koboToNaira(j['estimatedFareKobo']);
    final surge = _dbl(b['surgeMultiplier'], 1);
    return FareQuote(
      category: category,
      min: est,
      max: est,
      etaMin: etaMin,
      surge: surge > 1.0 ? surge : null,
      quoteId: j['quoteId']?.toString(),
      expiresAt: j['expiresAt'] == null ? null : _date(j['expiresAt']),
      breakdown: [
        ('Base fare', koboToNaira(b['baseFareKobo'])),
        ('Distance', koboToNaira(b['distanceFareKobo'])),
        ('Time', koboToNaira(b['timeFareKobo'])),
        ('Booking fee', koboToNaira(b['bookingFeeKobo'])),
        if (surge > 1.0) ('Surge ×$surge', est - koboToNaira(b['subtotalKobo'])),
      ],
    );
  }
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.isDefault = false,
    this.brand,
  });
  final String id;
  final PaymentMethodType type;
  final String label;
  final bool isDefault;
  final String? brand;

  IconData get icon => switch (type) {
    PaymentMethodType.card => Icons.credit_card_rounded,
    PaymentMethodType.wallet => Icons.account_balance_wallet_rounded,
    PaymentMethodType.cash => Icons.payments_rounded,
    PaymentMethodType.bankTransfer => Icons.account_balance_rounded,
  };
}

enum TxKind { trip, topUp, refund, tip }

class WalletTx {
  const WalletTx({
    required this.kind,
    required this.title,
    required this.date,
    required this.amount,
  });
  final TxKind kind;
  final String title;
  final DateTime date;

  /// Positive = credit, negative = debit (whole naira).
  final int amount;

  /// Ledger row from GET /payments/wallet/transactions.
  factory WalletTx.fromJson(Map<String, dynamic> j) {
    final type = '${j['type'] ?? j['kind'] ?? ''}'.toLowerCase();
    final kind = type.contains('top') || type.contains('deposit')
        ? TxKind.topUp
        : type.contains('refund')
        ? TxKind.refund
        : type.contains('tip')
        ? TxKind.tip
        : TxKind.trip;
    final amount = koboToNaira(j['amountKobo'] ?? j['amount']);
    final credit =
        j['direction'] == 'credit' || kind == TxKind.topUp || kind == TxKind.refund;
    return WalletTx(
      kind: kind,
      title: '${j['description'] ?? j['reference'] ?? 'Transaction'}',
      date: _date(j['createdAt']),
      amount: credit ? amount.abs() : -amount.abs(),
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.category,
    required this.fare,
    required this.date,
    required this.status,
    this.driver,
    this.stops = const [],
    this.distanceKm = 18.2,
    this.durationMin = 42,
    this.paymentMethod,
    this.reference,
    this.mode = TripMode.immediate,
    this.rated = false,
    this.pin,
    this.tip = 0,
    this.surgeMultiplier,
  });
  final String id;
  final Place pickup;
  final Place destination;
  final List<Place> stops;
  final VehicleCategory category;
  final int fare;
  final DateTime date;
  final TripStatus status;
  final Driver? driver;
  final double distanceKm;
  final int durationMin;
  final PaymentMethod? paymentMethod;
  final String? reference;
  final TripMode mode;
  final bool rated;

  /// PIN the rider shows the driver (only present on the rider's own trips).
  final String? pin;
  final int tip;
  final double? surgeMultiplier;

  bool get isActive =>
      status == TripStatus.matched ||
      status == TripStatus.driverArriving ||
      status == TripStatus.driverArrived ||
      status == TripStatus.inProgress;

  /// Trip row from POST /rides or GET /rides/:id (with optional driver/vehicle/stops).
  factory Trip.fromJson(Map<String, dynamic> j) {
    final driverJson = j['driver'] as Map?;
    final vehicleJson = j['vehicle'] as Map?;
    final fareKobo = j['finalFareKobo'] ?? j['estimatedFareKobo'];
    Place place(String addrKey, String latKey, String lngKey) {
      final lat = _dbl(j[latKey]);
      final lng = _dbl(j[lngKey]);
      return Place(
        name: '${j[addrKey] ?? ''}',
        address: '${j[addrKey] ?? ''}',
        lat: lat,
        lng: lng,
        at: projectToCanvas(lat, lng),
      );
    }

    final method = j['paymentMethod']?.toString();
    return Trip(
      id: '${j['id']}',
      pickup: place('pickupAddress', 'pickupLat', 'pickupLng'),
      destination: place('destinationAddress', 'destinationLat', 'destinationLng'),
      stops: [
        for (final s in (j['stops'] as List? ?? const []))
          Place(
            name: '${s['address']}',
            address: '${s['address']}',
            lat: _dbl(s['lat']),
            lng: _dbl(s['lng']),
            at: projectToCanvas(_dbl(s['lat']), _dbl(s['lng'])),
          ),
      ],
      category: VehicleCategory.fromWire(vehicleJson?['category']?.toString()),
      fare: koboToNaira(fareKobo),
      date: _date(j['scheduledFor'] ?? j['createdAt']),
      status: TripStatus.fromWire(j['status']?.toString()),
      driver: driverJson == null
          ? null
          : Driver.fromTripJson(
              Map<String, dynamic>.from(driverJson),
              vehicleJson == null ? null : Map<String, dynamic>.from(vehicleJson),
            ),
      distanceKm: _int(j['distanceMeters']) / 1000,
      durationMin: (_int(j['durationSeconds']) / 60).round(),
      paymentMethod: method == null
          ? null
          : PaymentMethod(
              id: 'pm',
              type: PaymentMethodType.fromWire(method),
              label: switch (method) {
                'cash' => 'Cash',
                'wallet' => 'NaijaMove Wallet',
                'bank_transfer' => 'Bank transfer',
                _ => 'Card',
              },
            ),
      reference: 'NM-${'${j['id']}'.replaceAll('-', '').padRight(8).substring(0, 8).toUpperCase()}',
      mode: TripMode.fromWire(j['mode']?.toString()),
      rated: j['rated'] == true,
      pin: j['pin']?.toString(),
      tip: koboToNaira(j['tipKobo']),
      surgeMultiplier: j['surgeMultiplier'] == null ? null : _dbl(j['surgeMultiplier'], 1),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.kind,
    this.unread = false,
  });
  final String title;
  final String body;
  final DateTime time;
  final NotificationKind kind;
  final bool unread;

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final cat = '${j['category'] ?? j['type'] ?? j['channel'] ?? ''}'.toLowerCase();
    return AppNotification(
      title: '${j['subject'] ?? j['title'] ?? 'Notification'}',
      body: '${j['body'] ?? j['message'] ?? ''}',
      time: _date(j['createdAt'] ?? j['sentAt']),
      kind: cat.contains('pay') || cat.contains('wallet')
          ? NotificationKind.payment
          : cat.contains('promo') || cat.contains('market')
          ? NotificationKind.promo
          : NotificationKind.trip,
      unread: j['readAt'] == null && j['read'] != true,
    );
  }
}

enum NotificationKind { trip, payment, promo }

class Promo {
  const Promo({
    required this.code,
    required this.description,
    required this.expires,
    this.active = true,
  });
  final String code;
  final String description;
  final DateTime expires;
  final bool active;

  factory Promo.fromJson(Map<String, dynamic> j) {
    final type = '${j['type']}';
    final desc = switch (type) {
      'percent_discount' => '${_int(j['valuePercent'])}% off your ride',
      'free_ride' => 'A free ride on us',
      'cashback' => '₦ ${koboToNaira(j['valueKobo'])} cashback',
      _ => '₦ ${koboToNaira(j['valueKobo'])} off your next ride',
    };
    return Promo(
      code: '${j['code']}',
      description: desc,
      expires: j['endsAt'] == null
          ? DateTime.now().add(const Duration(days: 30))
          : _date(j['endsAt']),
      active: j['isActive'] != false,
    );
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    this.sharesTrips = true,
    this.id,
  });
  final String? id;
  final String name;
  final String phone;
  final bool sharesTrips;

  factory EmergencyContact.fromJson(Map<String, dynamic> j) => EmergencyContact(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
    sharesTrips: j['shareTrips'] == true,
  );
}

class SupportCase {
  const SupportCase({
    required this.reference,
    required this.title,
    required this.icon,
    required this.status,
    required this.preview,
    required this.updated,
    this.unread = false,
    this.trip,
    this.id,
    this.category,
  });
  final String? id;
  final String reference;
  final String title;
  final IconData icon;
  final CaseStatus status;
  final String preview;
  final DateTime updated;
  final bool unread;
  final Trip? trip;
  final String? category;

  /// Either the server id or the display reference — whatever routes to detail.
  String get key => id ?? reference;

  factory SupportCase.fromJson(Map<String, dynamic> j) {
    final cat = '${j['category'] ?? 'other'}';
    final id = '${j['id']}';
    return SupportCase(
      id: id,
      reference: 'NM-${id.replaceAll('-', '').padRight(8).substring(0, 8).toUpperCase()}',
      title: '${j['subject'] ?? cat}',
      icon: switch (cat) {
        'trip' => Icons.directions_car_rounded,
        'payment' => Icons.credit_card_rounded,
        'safety' => Icons.shield_rounded,
        'driver' => Icons.person_rounded,
        'vehicle' => Icons.local_taxi_rounded,
        'account' => Icons.lock_outline_rounded,
        _ => Icons.chat_bubble_outline_rounded,
      },
      status: CaseStatus.fromWire(j['status']?.toString()),
      preview: '${j['lastMessage'] ?? j['subject'] ?? ''}',
      updated: _date(j['updatedAt'] ?? j['createdAt']),
      category: cat,
      unread: j['status'] == 'pending_user',
    );
  }
}

enum MessageSender { rider, agent, driver, system }

class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.read = true,
    this.imageAttachment = false,
  });
  final MessageSender sender;
  final String text;
  final DateTime time;
  final bool read;
  final bool imageAttachment;

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final authorType = '${j['authorType'] ?? 'user'}';
    return ChatMessage(
      sender: switch (authorType) {
        'agent' => MessageSender.agent,
        'system' => MessageSender.system,
        'driver' => MessageSender.driver,
        _ => MessageSender.rider,
      },
      text: '${j['body'] ?? ''}',
      time: _date(j['createdAt']),
    );
  }
}

class Review {
  const Review({
    required this.stars,
    required this.tags,
    required this.date,
    this.comment,
  });
  final int stars;
  final List<String> tags;
  final DateTime date;
  final String? comment;
}

class FaqArticle {
  const FaqArticle({
    required this.title,
    required this.category,
    required this.breadcrumb,
    required this.intro,
    required this.steps,
    required this.highlight,
    required this.tip,
    required this.related,
  });
  final String title;
  final String category;
  final List<String> breadcrumb;
  final String intro;
  final List<String> steps;
  final String highlight;
  final String tip;
  final List<String> related;
}

/// GET /riders/me
class RiderProfile {
  const RiderProfile({
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.preferredPaymentMethod,
  });
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final double rating;
  final int totalTrips;
  final String? preferredPaymentMethod;

  bool get needsName => name.trim().isEmpty;

  factory RiderProfile.fromJson(Map<String, dynamic> j) => RiderProfile(
    userId: '${j['userId'] ?? j['id']}',
    name: '${j['name'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
    email: j['email']?.toString(),
    rating: _dbl(j['rating'], 5),
    totalTrips: _int(j['totalTrips']),
    preferredPaymentMethod: j['preferredPaymentMethod']?.toString(),
  );
}

/// POST /maps/route
class RouteInfo {
  const RouteInfo({required this.distanceMeters, required this.durationSeconds, this.polyline});
  final int distanceMeters;
  final int durationSeconds;
  final String? polyline;
  double get km => distanceMeters / 1000;
  int get minutes => (durationSeconds / 60).round();

  factory RouteInfo.fromJson(Map<String, dynamic> j) => RouteInfo(
    distanceMeters: _int(j['distanceMeters']),
    durationSeconds: _int(j['durationSeconds']),
    polyline: j['polyline']?.toString(),
  );
}

/// POST /payments/wallet/topup/initialize → Paystack checkout.
class TopUpIntent {
  const TopUpIntent({required this.authorizationUrl, required this.reference});
  final String authorizationUrl;
  final String reference;
  factory TopUpIntent.fromJson(Map<String, dynamic> j) => TopUpIntent(
    authorizationUrl: '${j['authorizationUrl']}',
    reference: '${j['reference']}',
  );
}

/// POST /auth/otp/verify
class AuthResult {
  const AuthResult({required this.userId, required this.isNewUser, this.name});
  final String userId;
  final bool isNewUser;
  final String? name;
}
