# Vehicle Loading Dock

**You drive. The dock handles the cargo.**

Vehicle Loading Dock adds a dock that automatically loads and unloads the trunk of a parked vehicle. An early-to-mid-game logistics option before you build a large railway or robot network.

![Loading and unloading iron plates and uranium ore between two docks](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/master/portal/gallery/05-demonstration.gif)

## Easy parking

Place the dock, connect it to power, choose your filters and park your vehicle in the open area. The vehicle simply needs to be entirely inside the area and stationary for loading and unloading to take place.

## Buffer storage

The dock has a **100-slot buffer inventory**. Fill or empty it manually or with regular inserters.

Transfers between this inventory and the vehicle are automatic:

- **Loading:** up to ten item types, from the dock into the vehicle trunk.
- **Unloading:** up to ten item types, from the vehicle trunk into the dock.
- Unloading happens first, followed by loading.
- Transfers are instant, limited by the space actually available.
- Item quality and metadata are preserved.

Filters do not set quantities. An item may appear in both lists: it will be unloaded first, then loaded again.

![Loading and unloading filter configuration](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/master/portal/gallery/03-configuration.png)

## See both inventories from your vehicle

While you occupy or remotely drive a vehicle entirely inside the dock area, a sidebar automatically shows:

- the vehicle trunk contents;
- the dock inventory contents;
- quantities grouped by item and quality;
- occupied slots in each inventory.

![Automatic vehicle and dock inventory summary](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/master/portal/gallery/04-resume-stocks.png)

## Parking status light

A light on the machinery strip indicates the dock's state:

- **Orange:** powered and waiting for exactly one correctly parked vehicle.
- **Green:** one supported vehicle is entirely inside the area and stationary.
- **Off:** insufficient power; transfers are paused.

![A powered dock waiting for a vehicle with an orange light](https://raw.githubusercontent.com/Kardorio/vehicule_loading_dock/master/portal/gallery/01-attente.png)

## Research and construction

The dock is unlocked by **Automobilism**.

**Recipe:** 20 iron plates, 20 iron gear wheels, 10 electronic circuits and 2 iron chests.

With **Pyanodon Petroleum Handling**, the 20 iron gear wheels are replaced by **20 small parts, tier 1** (`small-parts-01`), and the 10 electronic circuits by **5 engine units** (`engine-unit`). The dock is still unlocked by the pack's Automobilism technology.

**Power:** constant consumption of **30 kW**. The dock must be covered by a powered electric network.

## Supported vehicles

Cars, tanks and spidertrons, including modded vehicles using the `car` or `spider-vehicle` types with a compatible trunk.

Only the trunk is handled. Fuel, ammunition and equipment are not transferred.

## Settings and saves

Blueprints preserve filters. After mining and rebuilding the dock, its filters are empty. Direct settings copy-and-paste between docks is not supported. Rotation preserves stored cargo and is rejected if the new machinery strip is obstructed.

## Compatibility

**Factorio 2.1 only.** No additional mods are required. In-game text is available in English and French.

The recipe adapts to Pyanodon Petroleum Handling. Nullius and Ultracube do not have dedicated compatibility in this version.