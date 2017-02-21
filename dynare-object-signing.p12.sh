#!/bin/sh

# (C) DynareTeam 2017
#
# This file is part of dynare-build project. Sources are available at:
#
#     https://gitlab.com/DynareTeam/dynare-build.git
#
# Dynare-build is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dynare-build is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

gpg --yes --always-trust --output dynare-object-signing.p12 --decrypt dynare-object-signing.p12.gpg
ERROR_CODE=$?
if [ $ERROR_CODE -ne 0 ]; then
    touch impossible-to-sign-dynare
else
    rm -f impossible-to-sign-dynare
fi
