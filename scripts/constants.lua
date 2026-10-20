local C = {
  name = "vehicle-loading-dock",
  circuit_name = "vld-circuit-output",
  parked_signal = "vld-vehicle-present",
  inventory_name = "vld-inventory",
  check_interval = 10,
  stop_speed_epsilon = 0.001,
  filter_count = 10,
  inventory_size = 100,
  legacy_inventory_size = 50,
  power_usage_watts = 30000,
}

C.energy_per_check = C.power_usage_watts * C.check_interval / 60

return C
