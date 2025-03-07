.. _examples-chicane:

Chicane
=======

Berlin-Zeuthen magnetic bunch compression chicane:
https://www.desy.de/csr/

All parameters can be found online.
A 5 GeV electron bunch with normalized transverse rms emittance of 1 um undergoes longitudinal compression by a factor of 10 in a standard 4-bend chicane.

The emittances should be preserved, and the rms pulse length should decrease by the compression factor (10).

In this test, the initial and final values of :math:`\sigma_x`, :math:`\sigma_y`, :math:`\sigma_t`, :math:`\epsilon_x`, :math:`\epsilon_y`, and :math:`\epsilon_t` must agree with nominal values.


Run
---

This example can be run as a Python script (``python3 run_chicane.py``) or with an app with an input file (``impactx input_chicane.in``).
Each can also be prefixed with an `MPI executor <https://www.mpi-forum.org>`__, such as ``mpiexec -n 4 ...`` or ``srun -n 4 ...``, depending on the system.

.. tab-set::

   .. tab-item:: Python Script

       .. literalinclude:: run_chicane.py
          :language: python3
          :caption: You can copy this file from ``examples/chicane/run_chicane.py``.

   .. tab-item:: App Input File

       .. literalinclude:: input_chicane.in
          :language: ini
          :caption: You can copy this file from ``examples/chicane/input_chicane.in``.


Analyze
-------

We run the following script to analyze correctness:

.. dropdown:: Script ``analysis_chicane.py``

   .. literalinclude:: analysis_chicane.py
      :language: python3
      :caption: You can copy this file from ``examples/chicane/analysis_chicane.py``.


Visualize
---------

You can run the following script to visualize the beam evolution over time:

.. dropdown:: Script ``plot_chicane.py``

   .. literalinclude:: plot_chicane.py
      :language: python3
      :caption: You can copy this file from ``examples/chicane/plot_chicane.py``.

.. figure:: https://user-images.githubusercontent.com/1353258/180332191-f9ce11fc-8c56-4713-a91a-2ad12ab09805.png
   :alt: Chicane floorplan, beam width and restored emittane in our Chicane benchmark

   (top) Chicane floorplan.
   (bottom) Chicane beam width and emittance evolution.

.. figure:: https://user-images.githubusercontent.com/1353258/181611473-754dde72-3281-453b-9d9a-43317a5a49f2.png
   :alt: Beam transversal compression in our chicane example.

   Chicane beam width and emittance evolution
