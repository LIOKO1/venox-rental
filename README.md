# venox-rental

Simple vehicle rental resource for FiveM.

## Framework Support

- QB Core
- Qbox
- ESX
- Standalone

Set `Config.Framework = 'auto'` to let the script detect your framework, or force one with `qb`, `qbox`, `esx`, or `standalone`.

## Features

- Clean marker interaction
- Text UI interaction support
- `qb-target` support
- `ox_target` support
- Clean built-in NUI rental menu
- Configurable rental locations
- Configurable vehicles and prices
- Cash or bank payment
- One active rental per player option
- Return points with optional refund
- Optional QB/Qbox key handoff
- Optional LegacyFuel/cdn-fuel support

## Install

1. Put this folder in your resources directory.
2. Add this to `server.cfg`:

```cfg
ensure venox-rental
```

3. Edit `config.lua` for your locations, cars, prices, and payment settings.

## Interaction

Choose your interaction style in `config.lua`:

```lua
Config.Interaction = 'auto' -- auto, textui, qb-target, ox_target
Config.ShowMarkers = true
```

`auto` uses `ox_target` first, then `qb-target`, then text UI.

Text UI settings:

```lua
Config.TextUI = {
    provider = 'auto', -- auto, ox_lib, qb-core, esx_textui, draw3d
    position = 'left-center'
}
```

The interaction mode controls how players open the rental menu. The vehicle selection itself uses the built-in NUI.

Target settings:

```lua
Config.Target = {
    distance = 2.5,
    icon = 'fas fa-car',
    rentLabel = 'Rent Vehicle',
    returnLabel = 'Return Rental'
}
```

## Configuration

Vehicles:

```lua
Config.Vehicles = {
    { label = 'Blista', model = 'blista', price = 250 },
    { label = 'Panto', model = 'panto', price = 200 }
}
```

Locations:

```lua
Config.Locations = {
    {
        label = 'Legion Square Rental',
        coords = vec4(220.41, -860.18, 30.20, 341.0),
        spawn = vec4(229.14, -800.82, 30.57, 158.5),
        returnCoords = vec3(232.47, -793.71, 30.58)
    }
}
```

## Notes

For standalone servers, rentals are free by default through `Config.StandaloneFree = true`.
