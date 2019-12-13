# Working Pacemaker

A Flutter demo application for mobile and web. 

## For Mobile (iOS and Android)

### Prerequisites

**Firebase analytics setup is necessary before building this app.**

### Dev

```
flutter run --target='lib/main_dev.dart'
```

### Production

```
flutter run --target='lib/main_production.dart'
```

## For Web

**Flutter Web Support is required. (As of 14 Dec, beta channel or higher.)**

### Dev

```
flutter run -d chrome --target='lib/main_web_dev.dart'
```

### Production

``` 
flutter run -d chrome --target='lib/main_web_production.dart'
```

### Build Production

```
flutter build web --target lib/main_web_production.dart
```

## Testing

### Unit / Widget

```shell
flutter test
```


### Integration

```shell
./test_driver/run.sh
```

## Intl

### Generate intl_messages.arb from Messages getters.

```shell
flutter packages pub run intl_translation:extract_to_arb \
  --locale=messages \
  --output-dir=lib/src/localization/messages \
  lib/src/localization/messages.dart
```

### Generate messages_xxx.dart from locale arbs.

```shell
flutter packages pub run intl_translation:generate_from_arb \
  --output-dir=lib/src/localization/generated \
  --no-use-deferred-loading \
  lib/src/localization/messages.dart \
  lib/src/localization/messages/intl_*.arb
```

# Application Architecture Note (TBE)

## MVS (Model, View, Subject, with stream) architecture

### Model

Application's model. Everyone should agree on this terminology.

## Subject (A.K.A ViewModel, as in MVVM pattern)
 
Application's Controller + Presenter.

* Controller interprets user actions from View, and sends messages to Model.
* Presenter creates ViewModel (DTO) from Model for View. 

Subject depends on Model.

### View

Application's View.

It consists of Flutter Widgets. View depends on Subject.

## Platform Object

TBE.