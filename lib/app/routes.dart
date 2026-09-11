/// Route paths — one place, referenced everywhere.
abstract final class Routes {
  // Flow 1 — Onboarding & Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const profileSetup = '/auth/profile';

  // Shell tabs
  static const home = '/home';
  static const trips = '/trips';
  static const wallet = '/wallet';
  static const profile = '/profile';

  // Flow 2 — Ride request
  static const search = '/search';
  static const rideOptions = '/ride/options';
  static const confirmRide = '/ride/confirm';
  static const scheduleRide = '/ride/schedule';
  static const negotiateRide = '/ride/negotiate';

  // Flow 3 — Active trip
  static const searching = '/trip/searching';
  static const driverMatched = '/trip/matched';
  static const driverArriving = '/trip/arriving';
  static const driverArrived = '/trip/arrived';
  static const tripInProgress = '/trip/progress';
  static const sos = '/trip/sos';
  static const tripCompleted = '/trip/completed';
  static const driverCancelled = '/trip/cancelled';
  static const driverChat = '/trip/chat';

  // Flow 4 — Wallet
  static const topUp = '/wallet/top-up';
  static const transactions = '/wallet/transactions';
  static const addCard = '/wallet/add-card';

  // Flow 5 — Trips
  static String receipt(String id) => '/trips/$id';
  static const receiptPattern = '/trips/:id';

  // Flow 6 — Profile
  static const savedPlaces = '/profile/places';
  static const emergencyContacts = '/profile/contacts';
  static const promotions = '/profile/promos';
  static const myRating = '/profile/rating';

  // Flow 7
  static const notifications = '/notifications';

  // Flow 9
  static const whatsapp = '/whatsapp';

  // Flow 10 — Rating
  static const rate = '/rating';
  static const tip = '/rating/tip';
  static const ratingDone = '/rating/done';
  static String driverProfile(String id) => '/driver/$id';
  static const driverProfilePattern = '/driver/:id';
  static const reportDriver = '/report';

  // Flow 11 — Support
  static const support = '/support';
  static const issueCategory = '/support/category';
  static const issueForm = '/support/form';
  static const caseSubmitted = '/support/submitted';
  static const myCases = '/support/cases';
  static String caseDetail(String ref) => '/support/cases/$ref';
  static const caseDetailPattern = '/support/cases/:ref';
  static const caseResolved = '/support/resolved';
  static const faq = '/support/faq';
}
