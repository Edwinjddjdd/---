import csv
import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PARAMS = ROOT / "data" / "derived" / "stage2_seed_parameters.json"
OUT_SUMMARY = ROOT / "data" / "derived" / "stage2_sanity_summary.csv"
OUT_VRS_GRID = ROOT / "data" / "derived" / "stage2_vrs_trigger_grid.csv"


def hover_metrics(case, rho, g):
    mass = case["mass_kg"]
    radius = case["main_rotor_radius_m"]
    area = math.pi * radius * radius
    weight = mass * g
    vi = math.sqrt(weight / (2.0 * rho * area))
    ideal_power_kw = weight * vi / 1000.0
    disk_loading_kg_m2 = mass / area
    tip_speed = case.get("main_rotor_tip_speed_m_s")
    omega_rad_s = tip_speed / radius if tip_speed else None

    row = {
        "case": "",
        "mass_kg": mass,
        "radius_m": radius,
        "disk_loading_kg_m2": disk_loading_kg_m2,
        "ideal_hover_vi_m_s": vi,
        "ideal_hover_power_kw": ideal_power_kw,
        "omega_rad_s": omega_rad_s if omega_rad_s is not None else "",
        "available_or_actual_power_kw": "",
        "ideal_to_power_ratio": "",
        "main_rotor_torque_nm": "",
        "simple_tail_thrust_n": "",
        "tail_ideal_power_kw": "",
    }

    actual_power = case.get("main_rotor_actual_power_kw") or case.get("engine_total_power_kw")
    if actual_power:
        row["available_or_actual_power_kw"] = actual_power
        row["ideal_to_power_ratio"] = ideal_power_kw / actual_power

    if case.get("main_rotor_actual_power_kw") and omega_rad_s:
        torque = case["main_rotor_actual_power_kw"] * 1000.0 / omega_rad_s
        tail_thrust = torque / case["tail_rotor_arm_m"]
        tail_area = math.pi * case["tail_rotor_radius_m"] ** 2
        tail_vi = math.sqrt(tail_thrust / (2.0 * rho * tail_area))
        tail_power_kw = tail_thrust * tail_vi / case["tail_rotor_efficiency"] / 1000.0
        row["main_rotor_torque_nm"] = torque
        row["simple_tail_thrust_n"] = tail_thrust
        row["tail_ideal_power_kw"] = tail_power_kw

    return row


def vrs_trigger(vh, vd, theta0_positive, thresholds):
    return int(
        theta0_positive
        and vh < thresholds["low_horizontal_speed_m_s"]
        and vd > thresholds["descent_rate_trigger_m_s"]
    )


def main():
    params = json.loads(PARAMS.read_text(encoding="utf-8"))
    rho = params["metadata"]["rho_sea_level_kg_m3"]
    g = params["metadata"]["g_m_s2"]

    cases = {
        "course_z11_hover_example": params["course_z11_hover_example"],
        "z10_public_low_estimate": params["z10_public_low_estimate"],
        "z10_public_high_estimate": params["z10_public_high_estimate"],
    }

    rows = []
    for name, case in cases.items():
        row = hover_metrics(case, rho, g)
        row["case"] = name
        rows.append(row)

    with OUT_SUMMARY.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    thresholds = params["vrs_seed_thresholds"]
    with OUT_VRS_GRID.open("w", newline="", encoding="utf-8") as f:
        fieldnames = ["horizontal_speed_m_s", "descent_rate_m_s", "theta0_positive", "s_vrs"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for vh in [0, 2, 4, 6, 8, 10, 12, 14, 16, 20]:
            for vd in [0, 0.75, 1.52, 2.0, 3.0, 5.0, 8.0]:
                writer.writerow(
                    {
                        "horizontal_speed_m_s": vh,
                        "descent_rate_m_s": vd,
                        "theta0_positive": True,
                        "s_vrs": vrs_trigger(vh, vd, True, thresholds),
                    }
                )

    for row in rows:
        print(
            f"{row['case']}: disk_loading={row['disk_loading_kg_m2']:.2f} kg/m^2, "
            f"vi={row['ideal_hover_vi_m_s']:.2f} m/s, "
            f"Pideal={row['ideal_hover_power_kw']:.1f} kW"
        )
    print(f"wrote {OUT_SUMMARY}")
    print(f"wrote {OUT_VRS_GRID}")


if __name__ == "__main__":
    main()
