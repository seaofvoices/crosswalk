# Changelog

## Unreleased Changes

## [0.2.1](https://github.com/seaofvoices/crosswalk/releases/tag/v0.2.1)

* Fix crosswalk-client and crosswalk-server package to export types ([#35](https://github.com/seaofvoices/crosswalk/pull/35))
* Add check to verify that `Init` and `Start` functions do not yield in dev mode ([#34](https://github.com/seaofvoices/crosswalk/pull/34))
* Add profile labels to `Init`, `Start`, `OnPlayerReady` and `OnPlayerLeaving` in DEV mode or when `_G.CROSSWALK_PROFILE` is `true` ([#32](https://github.com/seaofvoices/crosswalk/pull/32))

## [0.2.0](https://github.com/seaofvoices/crosswalk/releases/tag/v0.2.0)

* Add filter options to support class-like modules ([#26](https://github.com/seaofvoices/crosswalk/pull/26))
* Fix client loader to send ready signal after receiving server modules data ([#25](https://github.com/seaofvoices/crosswalk/pull/25))
* Add recursive module loading ([#22](https://github.com/seaofvoices/crosswalk/pull/22))
* Add support for providing external modules ([#16](https://gitlab.com/seaofvoices/crosswalk/-/merge_requests/16))
* Update client loader ([#15](https://gitlab.com/seaofvoices/crosswalk/-/merge_requests/15))
* Update server loader ([#14](https://gitlab.com/seaofvoices/crosswalk/-/merge_requests/14))

## [0.1.0](https://github.com/seaofvoices/crosswalk/releases/tag/v0.1.0)

Initial release of crosswalk.
