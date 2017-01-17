#!/bin/bash

# (C) DynareTeam 2017
#
# This file is part of dynare-build project. Sources are available at:
#
#     https://gitlab.com/DynareTeam/dynare-build.git
#
# Dynare is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dynare is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

PACKAGES=$(cat libs/requirements.txt)
PACKAGES="$PACKAGES $(cat requirements.txt)"

if [ $EUID -ne 0  ]; then
    sudo apt-get install $PACKAGES
    sudo apt-get autoremove
    sudo apt-get clean
else
    apt-get install $PACKAGES
    apt-get autoremove
    apt-get clean
fi
