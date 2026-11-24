class_name SunlightFxSettings
extends Resource

@export_range(0.1, 2.0) var collector_duration: float = 0.48
@export_range(0.1, 1.5) var fade_in: float = 0.26
@export_range(0.1, 6.0) var hold: float = 2.26
@export_range(0.1, 2.0) var fade_out: float = 0.88
@export_range(0.1, 2.0) var light_reveal_duration: float = 0.68
@export_range(0.0, 2.0) var melt_delay: float = 0.38
@export_range(0.1, 2.0) var melt_duration: float = 1.68
@export var light_enabled: bool = true
@export var frost_enabled: bool = true
@export var drops_enabled: bool = true
@export_range(0, 8, 1) var drop_count: int = 6
@export_range(0.4, 1.5) var drop_size: float = 1.5
@export_range(0.6, 6.0) var halo_period: float = 1.2
@export_range(0.0, 0.4) var halo_amplitude: float = 0.28
@export_range(0, 32, 1) var sun_particle_count: int = 6
@export_range(0.1, 1.4) var sun_particle_size: float = 0.5
@export_range(4.0, 36.0) var sun_particle_speed: float = 26.0
@export_range(0.6, 3.0) var sun_particle_lifetime: float = 0.8
@export_range(0.0, 1.0) var sun_particle_opacity: float = 0.85
@export_range(0, 24, 1) var cold_particle_count: int = 18
@export_range(0.08, 0.65) var cold_particle_size: float = 0.4032
@export_range(10.0, 60.0) var cold_particle_speed: float = 44.0
@export_range(0.8, 3.5) var cold_particle_lifetime: float = 3.2
@export_range(0.0, 1.0) var cold_particle_opacity: float = 0.325
@export var halo_enabled: bool = true
@export var sun_particles_enabled: bool = true
@export var cold_enabled: bool = true


func duration() -> float:
	return maxf(fade_in + hold + fade_out, melt_delay + melt_duration)


func halo_pulse(clock: float) -> float:
	return 0.5 - 0.5 * cos(clock / maxf(0.1, halo_period) * TAU)


func to_config() -> Dictionary:
	var result: Dictionary = {}
	for property: Dictionary in get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[String(property["name"])] = get(property["name"])
	return result
