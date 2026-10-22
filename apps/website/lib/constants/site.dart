/// Who is responsible for the data this site collects (the controller) and
/// where to write about it. Named in the privacy notice, the sign-up form and
/// the mail pages; a fork that runs its own site changes these.
const controllerName = 'USŁUGI IT Ryszard Schossler';

/// NIP; the EU VAT number is the same digits with a `PL` prefix.
const controllerTaxId = '6020147376';

const contactEmail = 'r.schossler@rsapps.org';

/// Where the site is served, for the absolute URLs that link previews need
/// (`og:url`, `og:image`). The deploy workflow sets it per target.
const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'http://localhost:8080');

/// The home page's summary: the meta description and the link preview text.
const siteDescription =
    'Książka klientów w telefonie dla kominiarzy i serwisantów. Pamięta terminy przeglądów, '
    'sama wysyła klientom SMS i pokazuje kartę klienta, gdy dzwoni.';
