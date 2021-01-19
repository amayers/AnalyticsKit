# AnalyticsKit

A package that defines a basic custom analytics sending service. 

### Usage
First you need to choose which service(s) that you want to send your analytics to.
Mixpanel is the only service built in, but you can easily add your own by subclassing `AnalyticsService` or `BatchSendingAnalyticsService`.

```
let mixpanelService = MixpanelAnalyticsService(token: <your API token here>)
let manager = AnalyticsManager.shared
manager.add(service: mixpanelService)
```

You can add as many services as you want.

Now you are all configured and ready to send events.
There is one predefined event, that is the `AppLaunchEvent`. It tracks device details, OS version & app version.
Sending events is simple:

```
let event = AppLaunchEvent()
manager.logCustomEvent(event)
```

With the `BatchSendingAnalyticsService` it is setup to batch up event sending, and only send them when a bunch have been "sent" or when the app is being exited.

### Creating custom events
Create a type that implements `AnalyticsEvent`, and pass an instance to `manager.logCustomEvent(event)`.

### Creating custom services
You will want to either subclass `BatchSendingAnalyticsService` or implement `AnalyticsService`. Then just add the service just like the example above does with Mixpanel. Generally you should subclass `BatchSendingAnalyticsService` unless you have a specific reason that batching up your events shouldn't happen. Look at `MixpanelAnalyticsService` for an example of how to subclass `BatchSendingAnalyticsService`.
