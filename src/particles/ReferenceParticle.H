/* Copyright 2022 The Regents of the University of California, through Lawrence
 *           Berkeley National Laboratory (subject to receipt of any required
 *           approvals from the U.S. Dept. of Energy). All rights reserved.
 *
 * This file is part of ImpactX.
 *
 * Authors: Axel Huebl
 * License: BSD-3-Clause-LBNL
 */
#ifndef IMPACTX_REFERENCE_PARTICLE_H
#define IMPACTX_REFERENCE_PARTICLE_H

#include <AMReX_BLassert.H>
#include <AMReX_Extension.H>
#include <AMReX_GpuQualifiers.H>
#include <AMReX_REAL.H>

#include <cmath>


namespace impactx
{
    /** This struct stores the reference particle attributes
     *  stored in ImpactXParticleContainer
     */
    struct RefPart
    {
        amrex::ParticleReal s = 0.0;  ///< integrated orbit path length, in meters
        amrex::ParticleReal x = 0.0;  ///< horizontal position x, in meters
        amrex::ParticleReal y = 0.0;  ///< vertical position y, in meters
        amrex::ParticleReal z = 0.0;  ///< longitudinal position y, in meters
        amrex::ParticleReal t = 0.0;  ///< clock time * c in meters
        amrex::ParticleReal px = 0.0; ///< momentum in x, normalized to proper velocity
        amrex::ParticleReal py = 0.0; ///< momentum in y, normalized to proper velocity
        amrex::ParticleReal pz = 0.0; ///< momentum in z, normalized to proper velocity
        amrex::ParticleReal pt = 0.0; ///< energy deviation, normalized by rest energy
        amrex::ParticleReal mass = 0.0; ///< reference rest mass, in kg
        amrex::ParticleReal charge = 0.0; ///< reference charge, in C

        /** Get reference particle relativistic gamma
         *
         * @returns relativistic gamma
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        gamma () const
        {
            amrex::ParticleReal const ref_gamma = -pt;
            return ref_gamma;
        }

        /** Get reference particle relativistic beta
         *
         * @returns relativistic beta
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        beta () const
        {
            using namespace amrex::literals;

            amrex::ParticleReal const ref_gamma = -pt;
            amrex::ParticleReal const ref_beta = sqrt(1.0_prt - 1.0_prt/pow(ref_gamma,2));
            return ref_beta;
        }

        /** Get reference particle beta*gamma
         *
         * @returns relativistic beta*gamma
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        beta_gamma () const
        {
            using namespace amrex::literals;

            amrex::ParticleReal const ref_gamma = -pt;
            amrex::ParticleReal const ref_betagamma = sqrt(pow(ref_gamma, 2) - 1.0_prt);
            return ref_betagamma;
        }

        /** Get reference particle rest mass
         *
         * @returns rest mass in MeV/c^2
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        mass_MeV () const
        {
            using namespace amrex::literals;

            constexpr double MeVc2_kg = 1.78266192e-30;
            return amrex::ParticleReal(mass / MeVc2_kg);
        }

        /** Set reference particle rest mass
         *
         * @param massE particle rest mass (MeV/c^2)
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        RefPart &
        set_mass_MeV (amrex::ParticleReal const massE)
        {
            using namespace amrex::literals;

            AMREX_ASSERT_WITH_MESSAGE(massE != 0.0_prt,
                                      "set_mass_MeV: Mass cannot be zero!");

            constexpr amrex::ParticleReal MeVc2_kg = 1.78266192e-30;
            mass = massE * MeVc2_kg;

            // re-scale pt and pz
            if (pt != 0.0_prt)
            {
                pt = -energy_MeV() / massE - 1.0_prt;
                pz = sqrt(pow(pt, 2) - 1.0_prt);
            }

            return *this;
        }

        /** Get reference particle energy
         *
         * @returns kinetic energy in MeV
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        energy_MeV () const
        {
            using namespace amrex::literals;

            amrex::ParticleReal const ref_gamma = -pt;
            amrex::ParticleReal const ref_energy = mass_MeV() * (ref_gamma - 1.0_prt);
            return ref_energy;
        }

        /** Set reference particle energy
         *
         * @param energy initial kinetic energy (MeV)
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        RefPart &
        set_energy_MeV (amrex::ParticleReal const energy)
        {
            using namespace amrex::literals;

            AMREX_ASSERT_WITH_MESSAGE(mass != 0.0_prt,
                                      "set_energy_MeV: Set mass first!");

            px = 0.0;
            py = 0.0;
            pt = -energy / mass_MeV() - 1.0_prt;
            pz = sqrt(pow(pt, 2) - 1.0_prt);

            return *this;
        }

        /** Get reference particle charge
         *
         * @returns charge in multiples of the (positive) elementary charge
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        charge_qe () const
        {
            using namespace amrex::literals;

            constexpr double qe = 1.602176634e-19;
            return amrex::ParticleReal(charge / qe);
        }

        /** Set reference particle charge
         *
         * @param charge_qe in multiples of the (positive) elementary charge
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        RefPart &
        set_charge_qe (amrex::ParticleReal const charge_qe)
        {
            using namespace amrex::literals;

            constexpr double qe = 1.602176634e-19;
            this->charge = charge_qe * qe;

            return *this;
        }

        /** Get reference particle charge to mass ratio
         *
         * @returns charge to mass ratio (elementary charge/eV)
         */
        AMREX_GPU_HOST_DEVICE AMREX_FORCE_INLINE
        amrex::ParticleReal
        qm_qeeV () const
        {
            return charge / mass;
        }
    };

} // namespace impactx

#endif // IMPACTX_REFERENCE_PARTICLE_H
