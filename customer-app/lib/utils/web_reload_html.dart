import 'dart:html' as html;

/// Web: hard-navigate to the app root. This fully reloads the SPA as a fresh
/// guest (no session), which is the most bulletproof "log out" possible — no
/// Flutter route transition, so no chance of a blank/white flash.
void reloadToHome() => html.window.location.assign('/');
