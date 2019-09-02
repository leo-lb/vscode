#!/usr/bin/python3
#
# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: MIT
#
# VSCode stores dependencies for their RPM package in a `dependencies.json`
# file This script parses the X86 dependencies from that file and checks to see
# if they are available on PPC64LE, by default printing a diff to use to patch
# the file. The `-i` option updates the file in place.
#

import argparse
import json
import subprocess as sp
import sys

from difflib import unified_diff
from os.path import normpath, dirname, realpath, join as joinpath
from typing import Dict, List

# This file is stored in the scripts/ folder under the VSCode root directory,
# so the below will get the VSCode root directory no matter where the script is
# called from
VSC_ROOT = normpath(joinpath(dirname(realpath(__file__)), '..'))

DEFAULT_DEPS_FILE = joinpath(VSC_ROOT, 'resources/linux/rpm/dependencies.json')
DNF_CMD_LIST = ['dnf', '-Cq', 'repoquery', '--qf', '%{name}', '--whatprovides']


def print_diff(rpm_deps_file: str, orig_deps: Dict[str, List[str]],
               ppc_deps: List[str]) -> None:
    rpm_deps_file = rpm_deps_file.replace(VSC_ROOT, '')

    a_lines = json.dumps(orig_deps, indent='\t').splitlines(keepends=True)

    orig_deps['ppc64le'] = ppc_deps
    b_lines = json.dumps(orig_deps, indent='\t').splitlines(keepends=True)

    sys.stdout.writelines(unified_diff(a_lines, b_lines,
                                       fromfile='a{}'.format(rpm_deps_file),
                                       tofile='b{}'.format(rpm_deps_file)))


def get_ppc_package_name(dep: str) -> str:
    return sp.check_output(DNF_CMD_LIST + [dep]).decode('utf-8').rstrip()


def load_json(path: str) -> Dict[str, List[str]]:
    with open(path) as fp:
        return json.load(fp)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='update VSCode rpm '
                                                 'dependencies file for PPC64')
    parser.add_argument('rpm_deps_file', metavar='DEPS_FILE', type=str,
                        nargs='?', default=DEFAULT_DEPS_FILE,
                        help='path to VSCode rpm dependencies.json file '
                             '(default: {})'.format(DEFAULT_DEPS_FILE))
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-i', '--in-place', action='store_true',
                       help='update dependencies file in-place')
    group.add_argument('-p', '--print-names', action='store_true',
                       help='just print names of dependencies instead of '
                            'outputting a diff file')
    parser.add_argument('-n', '--package-names', action='store_true',
                        dest='use_package_name', help='print a unique list of '
                                                      'package names instead '
                                                      'of a list of so names')
    parser.add_argument('-q', '--quiet', action='store_true',
                        help='do not display progress messages')

    return parser.parse_args()


def main() -> None:
    args = parse_args()
    orig_deps = load_json(args.rpm_deps_file)

    def msg(s: str) -> None:
        if not args.quiet:
            print(s, file=sys.stderr)
            sys.stderr.flush()

    ppc_deps = []
    for i, dep in enumerate(orig_deps['x86_64'], 1):
        msg('Checking {} ({} of {})'.format(dep, i, len(orig_deps['x86_64'])))

        ppc_package_name = get_ppc_package_name(dep)

        if ppc_package_name != '':
            msg('FOUND: {}'.format(ppc_package_name))
            if args.use_package_name:
                ppc_deps.append(ppc_package_name)
            else:
                ppc_deps.append(dep)

    if args.use_package_name:
        ppc_deps = sorted(set(ppc_deps))

    msg('Found {} PPC64 dependencies'.format(len(ppc_deps)))

    if args.print_names:
        print('\n'.join(sorted(set(ppc_deps))))
    elif 'ppc64le' in orig_deps and set(ppc_deps) == set(orig_deps['ppc64le']):
        msg('Correct PPC64 dependencies already included in dependencies.json')
    elif args.in_place:
        orig_deps['ppc64le'] = ppc_deps
        with open(args.rpm_deps_file, 'w') as fp:
            json.dump(orig_deps, fp, indent='\t')
    else:
        print_diff(args.rpm_deps_file, orig_deps, ppc_deps)


if __name__ == '__main__':
    main()
