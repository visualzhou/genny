from setuptools import setup

setup(name='genny',
      version='1.0',
      packages=['genny'],
      install_requires=[
          'nose==1.3.7',
          'yapf==0.24.0',
      ],
      setup_requires=[
          'nose==1.3.7'
      ],
      entry_points={
          'console_scripts': [
              'genny-metrics-summarize = genny.metrics_output_parser:main__sumarize',
              'genny-metrics-to-perf-json = genny.perf_json:main__summarize_translate',
          ]
      },
      )