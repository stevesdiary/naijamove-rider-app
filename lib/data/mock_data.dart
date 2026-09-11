import 'package:flutter/material.dart';

import 'models.dart';

/// Sample data from the spec's "Sample Data" table — used everywhere so screens agree.
abstract final class Mock {
  static const riderName = 'Tunde Adeyemi';
  static const riderPhone = '+234 803 123 4567';
  static const riderRating = 4.9;
  static const riderTrips = 42;
  static const walletBalance = 2400;
  static const tripPin = '4821';
  static const referralCode = 'TUNDE500';

  static const pickup = Place(
    name: 'Current location',
    address: '24 Adetokunbo Ademola St, Victoria Island',
    icon: Icons.my_location_rounded,
    at: Offset(0.3, 0.62),
  );
  static const destination = Place(
    name: 'Ikeja City Mall',
    address: 'Obafemi Awolowo Way, Alausa, Ikeja',
    icon: Icons.local_mall_outlined,
    distanceKm: 18.2,
    at: Offset(0.72, 0.18),
  );

  static const home = Place(
    name: 'Home',
    address: 'Lekki Phase 1',
    icon: Icons.home_rounded,
  );
  static const work = Place(
    name: 'Work',
    address: 'Marina, Lagos Island',
    icon: Icons.work_rounded,
  );

  static const suggestions = [
    destination,
    Place(name: 'Ikeja GRA', address: 'Isaac John St, Ikeja', distanceKm: 16.9),
    Place(
      name: 'Murtala Muhammed Airport (MMA2)',
      address: 'Ikeja, Lagos',
      icon: Icons.flight_takeoff_rounded,
      distanceKm: 19.4,
    ),
  ];
  static const recents = [
    Place(
      name: 'Marina, Lagos Island',
      address: 'CMS Bus Stop, Lagos Island',
      icon: Icons.history_rounded,
      distanceKm: 6.1,
    ),
    Place(
      name: 'Balogun Market',
      address: 'Lagos Island',
      icon: Icons.history_rounded,
      distanceKm: 5.8,
    ),
    Place(
      name: 'The Palms Shopping Mall',
      address: 'Bisway St, Maroko, Lekki',
      icon: Icons.history_rounded,
      distanceKm: 4.4,
    ),
  ];
  static const savedPlaces = [
    Place(
      name: "Mum's house",
      address: 'Bode Thomas St, Surulere',
      icon: Icons.star_rounded,
      distanceKm: 9.3,
    ),
    Place(
      name: 'Gym',
      address: 'Admiralty Way, Lekki Phase 1',
      icon: Icons.star_rounded,
      distanceKm: 3.1,
    ),
  ];

  static const vehicle = Vehicle(
    make: 'Toyota',
    model: 'Corolla',
    year: 2019,
    colour: 'White',
    plate: 'LND 482 KJ',
    category: VehicleCategory.economy,
  );

  static const driver = Driver(
    id: 'drv_1',
    name: 'Emeka Okafor',
    rating: 4.87,
    trips: 1240,
    vehicle: vehicle,
    memberSince: 2022,
    topDriver: true,
    bio:
        'Been driving in Lagos for 6 years. I know every shortcut from Lekki to Ikeja. AC always on.',
  );

  static const quotes = [
    FareQuote(
      category: VehicleCategory.economy,
      min: 1200,
      max: 1500,
      etaMin: 3,
    ),
    FareQuote(
      category: VehicleCategory.comfort,
      min: 2000,
      max: 2400,
      etaMin: 5,
      surge: 1.4,
    ),
    FareQuote(
      category: VehicleCategory.premium,
      min: 3500,
      max: 4200,
      etaMin: 6,
    ),
    FareQuote(category: VehicleCategory.xl, min: 2800, max: 3200, etaMin: 8),
  ];

  static const visa = PaymentMethod(
    id: 'pm_1',
    type: PaymentMethodType.card,
    label: 'Visa ending in 4242',
    isDefault: true,
    brand: 'Visa',
  );
  static const paymentMethods = [
    visa,
    PaymentMethod(
      id: 'pm_2',
      type: PaymentMethodType.bankTransfer,
      label: 'GTBank',
      brand: 'GTBank',
    ),
    PaymentMethod(id: 'pm_3', type: PaymentMethodType.cash, label: 'Cash'),
  ];

  static const fareRows = [
    ('Base fare', '₦ 500'),
    ('Distance (18.2 km)', '₦ 728'),
    ('Booking fee', '₦ 150'),
    ('Promo (WELCOME)', '−₦ 28'),
  ];
  static const fareEstimate = 1350;

  static final now = DateTime(2026, 9, 11, 15, 42);

  static final currentTrip = Trip(
    id: 'trp_now',
    pickup: pickup,
    destination: destination,
    category: VehicleCategory.economy,
    fare: fareEstimate,
    date: now,
    status: TripStatus.completed,
    driver: driver,
    paymentMethod: visa,
    reference: 'NM-TRX-8F2A91',
  );

  static final trips = <Trip>[
    currentTrip,
    Trip(
      id: 'trp_2',
      pickup: const Place(
        name: 'Lekki Phase 1',
        address: 'Admiralty Way',
        at: Offset(0.35, 0.7),
      ),
      destination: const Place(
        name: 'Eko Hotel & Suites',
        address: 'Adetokunbo Ademola St, VI',
        at: Offset(0.55, 0.3),
      ),
      category: VehicleCategory.comfort,
      fare: 2600,
      date: DateTime(2026, 9, 8, 19, 5),
      status: TripStatus.completed,
      driver: const Driver(
        id: 'drv_2',
        name: 'Blessing Adeyemi',
        rating: 4.92,
        trips: 860,
        vehicle: Vehicle(
          make: 'Honda',
          model: 'Accord',
          year: 2020,
          colour: 'Grey',
          plate: 'KJA 210 FT',
          category: VehicleCategory.comfort,
        ),
        memberSince: 2023,
      ),
      paymentMethod: visa,
      reference: 'NM-TRX-7C1D22',
      distanceKm: 6.4,
      durationMin: 24,
    ),
    Trip(
      id: 'trp_3',
      pickup: const Place(
        name: 'Marina',
        address: 'CMS Bus Stop',
        at: Offset(0.4, 0.5),
      ),
      destination: const Place(
        name: 'Balogun Market',
        address: 'Lagos Island',
        at: Offset(0.62, 0.45),
      ),
      category: VehicleCategory.economy,
      fare: 900,
      date: DateTime(2026, 9, 2, 11, 30),
      status: TripStatus.cancelled,
      reference: 'NM-TRX-6A0B77',
      distanceKm: 2.1,
      durationMin: 0,
    ),
    Trip(
      id: 'trp_4',
      pickup: const Place(
        name: 'The Palms',
        address: 'Lekki',
        at: Offset(0.3, 0.75),
      ),
      destination: const Place(
        name: 'MMA2',
        address: 'Ikeja',
        at: Offset(0.7, 0.15),
      ),
      category: VehicleCategory.xl,
      fare: 4100,
      date: DateTime(2026, 8, 24, 6, 15),
      status: TripStatus.completed,
      driver: driver,
      paymentMethod: const PaymentMethod(
        id: 'pm_3',
        type: PaymentMethodType.cash,
        label: 'Cash',
      ),
      reference: 'NM-TRX-5D9E10',
      distanceKm: 23.6,
      durationMin: 55,
    ),
    Trip(
      id: 'trp_sched',
      pickup: pickup,
      destination: const Place(
        name: 'Murtala Muhammed Airport T2',
        address: 'Ikeja',
        at: Offset(0.7, 0.15),
      ),
      category: VehicleCategory.comfort,
      fare: 3200,
      date: DateTime(2026, 9, 14, 5, 30),
      status: TripStatus.requested,
      mode: TripMode.scheduled,
      distanceKm: 21.0,
      durationMin: 48,
    ),
  ];

  static final transactions = <WalletTx>[
    WalletTx(
      kind: TxKind.trip,
      title: 'Trip to Ikeja City Mall',
      date: now,
      amount: -1350,
    ),
    WalletTx(
      kind: TxKind.tip,
      title: 'Tip · Emeka Okafor',
      date: now,
      amount: -200,
    ),
    WalletTx(
      kind: TxKind.topUp,
      title: 'Wallet top up · Visa ••4242',
      date: DateTime(2026, 9, 10, 9, 12),
      amount: 5000,
    ),
    WalletTx(
      kind: TxKind.trip,
      title: 'Trip to Eko Hotel & Suites',
      date: DateTime(2026, 9, 8, 19, 40),
      amount: -2600,
    ),
    WalletTx(
      kind: TxKind.refund,
      title: 'Refund · cancelled trip',
      date: DateTime(2026, 9, 2, 11, 45),
      amount: 800,
    ),
    WalletTx(
      kind: TxKind.trip,
      title: 'Trip to MMA2',
      date: DateTime(2026, 8, 24, 7, 10),
      amount: -4100,
    ),
  ];

  static final notifications = <AppNotification>[
    AppNotification(
      title: 'Your driver has arrived',
      body: 'Emeka is waiting in a white Toyota Corolla · LND 482 KJ',
      time: now.subtract(const Duration(minutes: 40)),
      kind: NotificationKind.trip,
      unread: true,
    ),
    AppNotification(
      title: 'Payment successful',
      body: '₦ 1,350 charged to Visa ••4242 for your trip to Ikeja City Mall',
      time: now.subtract(const Duration(minutes: 5)),
      kind: NotificationKind.payment,
      unread: true,
    ),
    AppNotification(
      title: '₦ 500 off your next 3 rides',
      body: 'Use code LAGOS500 before Sunday. T&Cs apply.',
      time: DateTime(2026, 9, 10, 8, 0),
      kind: NotificationKind.promo,
    ),
    AppNotification(
      title: 'Wallet topped up',
      body: '₦ 5,000 added to your NaijaMove Wallet',
      time: DateTime(2026, 9, 10, 9, 12),
      kind: NotificationKind.payment,
    ),
    AppNotification(
      title: 'Trip receipt ready',
      body: 'Your receipt for Eko Hotel & Suites is available',
      time: DateTime(2026, 9, 8, 19, 41),
      kind: NotificationKind.trip,
    ),
  ];

  static final promos = <Promo>[
    Promo(
      code: 'LAGOS500',
      description: '₦ 500 off your next 3 rides',
      expires: DateTime(2026, 9, 14),
    ),
    Promo(
      code: 'WEEKEND20',
      description: '20% off Comfort rides this weekend',
      expires: DateTime(2026, 9, 13),
    ),
    Promo(
      code: 'WELCOME',
      description: '₦ 300 off your first ride',
      expires: DateTime(2026, 8, 1),
      active: false,
    ),
  ];

  static const emergencyContacts = [
    EmergencyContact(name: 'Funmi Adeyemi', phone: '+234 802 555 0192'),
    EmergencyContact(
      name: 'Chidi Okonkwo',
      phone: '+234 705 118 2244',
      sharesTrips: false,
    ),
  ];

  static final cases = <SupportCase>[
    SupportCase(
      reference: 'NM-2026-00847',
      title: 'Incorrect charge',
      icon: Icons.credit_card_rounded,
      status: CaseStatus.open,
      preview: "Support: Thanks Tunde, we've reviewed the fare and…",
      updated: now.subtract(const Duration(hours: 2)),
      unread: true,
      trip: currentTrip,
    ),
    SupportCase(
      reference: 'NM-2026-00812',
      title: 'Lost item in vehicle',
      icon: Icons.search_rounded,
      status: CaseStatus.pendingAgent,
      preview: "You: It's a black umbrella with a wooden handle",
      updated: now.subtract(const Duration(days: 1)),
    ),
    SupportCase(
      reference: 'NM-2026-00790',
      title: 'Refund not received',
      icon: Icons.currency_exchange_rounded,
      status: CaseStatus.resolved,
      preview: 'Refund of ₦ 800 credited to your wallet',
      updated: DateTime(2026, 8, 12),
    ),
  ];

  static final caseThread = <ChatMessage>[
    ChatMessage(
      sender: MessageSender.system,
      text: 'Case opened',
      time: DateTime(2026, 9, 11, 15, 50),
    ),
    ChatMessage(
      sender: MessageSender.rider,
      text: 'I was quoted ₦ 1,200 but charged ₦ 1,350.',
      time: DateTime(2026, 9, 11, 15, 50),
    ),
    ChatMessage(
      sender: MessageSender.rider,
      text: 'Receipt screenshot',
      time: DateTime(2026, 9, 11, 15, 51),
      imageAttachment: true,
    ),
    ChatMessage(
      sender: MessageSender.system,
      text: 'Agent assigned',
      time: DateTime(2026, 9, 11, 15, 55),
    ),
    ChatMessage(
      sender: MessageSender.agent,
      text:
          'Hi Tunde, thanks for flagging this. I can see a surge multiplier was applied at 3:41 PM. Let me check whether it was shown before you confirmed.',
      time: DateTime(2026, 9, 11, 15, 58),
    ),
  ];

  static final driverThread = <ChatMessage>[
    ChatMessage(
      sender: MessageSender.driver,
      text: "I'm 2 minutes away, near Eko Hotel roundabout.",
      time: DateTime(2026, 9, 11, 15, 31),
    ),
    ChatMessage(
      sender: MessageSender.rider,
      text: "Okay, I'm at the gate by the security post.",
      time: DateTime(2026, 9, 11, 15, 31),
    ),
    ChatMessage(
      sender: MessageSender.driver,
      text: 'Which gate — the main one on Adetokunbo Ademola?',
      time: DateTime(2026, 9, 11, 15, 32),
    ),
    ChatMessage(
      sender: MessageSender.rider,
      text: 'Yes, the main gate. White Corolla right?',
      time: DateTime(2026, 9, 11, 15, 32),
    ),
  ];

  static const driverQuickReplies = [
    "I'm at the pickup point",
    'Running 2 min late',
    'Which gate/entrance?',
    'Please call me',
    "I'll be right out",
  ];

  static const driverStarDistribution = [78, 15, 4, 2, 1];
  static const riderStarDistribution = [88, 9, 3, 0, 0];
  static const driverCompliments = [
    ('Safe driving', 312),
    ('On time', 287),
    ('Friendly', 201),
    ('Clean car', 188),
  ];

  static final driverReviews = <Review>[
    Review(
      stars: 5,
      tags: ['Great driver', 'Safe driving'],
      date: now.subtract(const Duration(days: 2)),
      comment: 'Smooth ride through Third Mainland traffic.',
    ),
    Review(
      stars: 4,
      tags: ['On time'],
      date: now.subtract(const Duration(days: 7)),
    ),
    Review(
      stars: 5,
      tags: ['Friendly', 'Clean car'],
      date: now.subtract(const Duration(days: 12)),
      comment: 'AC was on the whole way. Very polite.',
    ),
  ];

  static final riderFeedback = <Review>[
    Review(
      stars: 5,
      tags: ['Polite', 'On time'],
      date: now.subtract(const Duration(days: 3)),
    ),
    Review(
      stars: 5,
      tags: ['Easy pickup'],
      date: now.subtract(const Duration(days: 7)),
    ),
    Review(stars: 4, tags: [], date: now.subtract(const Duration(days: 14))),
  ];

  static const faqs = [
    'How do upfront fares and surge pricing work?',
    'What should I do if I forgot an item in a car?',
    'How does the 4-digit PIN code protect my ride?',
    'Can I pay in cash or via direct bank transfer?',
    'How long do refunds take?',
    'How do I add an emergency contact?',
  ];

  static const refundArticle = FaqArticle(
    title: 'How long do refunds take?',
    category: 'Refunds',
    breadcrumb: ['Help', 'Payments', 'Refunds'],
    intro:
        'If a trip is cancelled or you were overcharged, NaijaMove refunds the difference to the payment method you used, or to your NaijaMove Wallet if you choose.',
    steps: [
      'Open the trip receipt',
      'Tap Report an Issue',
      "Choose 'I didn't receive my refund'",
    ],
    highlight:
        'Wallet refunds are instant; card refunds take 3–5 business days.',
    tip: "Choose 'Credit to wallet' for the fastest refund.",
    related: [
      'Why was I charged a cancellation fee?',
      'Understanding surge pricing',
      'How the fare floor works',
    ],
  );
}
