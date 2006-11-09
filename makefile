###########################################################################
#                              Vision2Pixels
#
#                            Copyright (C) 2006
#                       Pascal Obry - Olivier Ramonat
#
#   This library is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or (at
#   your option) any later version.
#
#   This library is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this library; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#  Simple makefile to build Vision2Pixels
###########################################################################

INSTALL=$(HOME)/opt/v2p

ifeq ($(OS),Windows_NT)
EXEXT=.exe
else
EXEXT=
endif

OPTIONS = INSTALL="$(INSTALL)" EXEXT="$(EXEXT)"

all: setup
	gnat make -XPRJ_Build=Debug -Pweb/web

setup:
	make -C web setup

install:
	make -C web install $(OPTIONS)

clean:
	gnat clean -r -Pweb/web
