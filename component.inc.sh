#!/bin/bash
COMPONENT_INC_SH="$(readlink -f "${BASH_SOURCE[0]}")"
export COMPONENT_INC_SH

COMPONENT_INITED=0
component(){
	local command="$1"; shift

	if [[ "$command" != "init" ]] && [[ "$COMPONENT_INITED" = "0" ]]; then
		printf 'run component init, first\n' >&2
		exit 1
	fi

	case "$command" in
		init)
			if [[ -z "$COMPONENT_BASE" ]]; then
				COMPONENT_BASE="/var/provision-components"
				if [[ ! -d "${COMPONENT_BASE}" ]]; then
					if ! mkdir -p "${COMPONENT_BASE}"; then
						exit 1
					fi
				fi
				export COMPONENT_BASE
			fi
			export COMPONENT_BASE

			if [[ -z "$COMPONENT_BASE_URL" ]]; then
				COMPONENT_BASE_URL="https://raw.githubusercontent.com/wpalmer/component/master"
			fi
			export COMPONENT_BASE_URL
			
			if [[ -z "$COMPONENT_ALIASES" ]]; then
				COMPONENT_ALIASES="/etc/component-aliases.lst"
			fi
			export COMPONENT_ALIASES
			
			if [[ -z "$COMPONENT_DEBUG" ]]; then
				COMPONENT_DEBUG="/dev/stderr"
			fi
			export COMPONENT_DEBUG

			if [[ -z "$COMPONENT_REGISTRY" ]]; then
				COMPONENT_REGISTRY="/var/provisioned-components.lst"
			fi
			export COMPONENT_REGISTRY

			COMPONENT_INITED=1
			;;
		alias)
			local pattern="$1"
			local substitution="$2"
			
			component alias-delete "$pattern"

			printf '%s\0%s\0' \
				"$pattern" \
				"$substitution" \
				>> "${COMPONENT_ALIASES}"
			;;
		alias-delete)
			local sought="$1"
			local pattern=
			local substitution=
			local part=

			[[ -e "${COMPONENT_ALIASES}" ]] || return 0
			mv "${COMPONENT_ALIASES}" "${COMPONENT_ALIASES}.old" || return 1
			while read -r -d $'\0' part; do
				[[ -z "$pattern" ]] && pattern="$part" && continue
				substitution="$part"

				if [[ "$pattern" != "$sought" ]]; then
					printf '%s\0%s\0' \
						"$pattern" \
						"$substitution" \
						>> "${COMPONENT_ALIASES}"
				fi
				pattern=
				substitution=
			done < <(cat "${COMPONENT_ALIASES}.old")
			;;
		expand)
			local component="$1"

			if [[ ! -r "${COMPONENT_ALIASES}" ]]; then
				printf '%s\n' "$component"
				return 0
			fi

			local pattern=
			local substitution=
			local part=
			while read -r -d $'\0' part; do
				[[ -z "$pattern" ]] && pattern="$part" && continue
				substitution="$part"

				component="$(sed -e "s!$pattern!$substitution!" <<<"$component")"

				pattern=
				substitution=
			done < <(cat "${COMPONENT_ALIASES}")

			printf '%s\n' "$component"
			return 0
			;;
		debug)
			{
				local first=1
				for s in "$@"; do
					[[ "$first" = "1" ]] && printf '%s' "$COMPONENT_INDENT" || printf ' '
					printf '%s' "$s"
					first=0
				done
				printf '\n'
			} >> "${COMPONENT_DEBUG}"
			;;
		prefix)
			COMPONENT_PREFIX="${COMPONENT_PREFIX}:$1"
			COMPONENT_PREFIX="${COMPONENT_PREFIX#:}"
			export COMPONENT_PREFIX
			return 0
			;;
		require)
			local component="$1"

			if ! component-require "${component}"; then
				exit 1
			fi
			;;
		acquire)
			local prefix
			local did_empty=0
			while read -r -d : prefix; do
				if [[ -z "$prefix" ]]; then
					[[ "$did_empty" = "1" ]] && continue
					did_empty=1
				fi

				local abs_component="$prefix/$component"
				abs_component="${abs_component#/}"
				abs_component="$(component expand "$abs_component")"
				
				local local_script=
				local base=
				while read -r -d : base; do
					[[ -z "$base" ]] && continue
					local_script="${base}/${abs_component}.sh"
					
					if [[ -x "${local_script}" ]]; then
						printf '%s\n' "${local_script}"
						return 0
					elif [[ -w "${local_script}" ]]; then
						chmod a+x "${local_script}" || return 1
						printf '%s\n' "${local_script}"
						return 0
					fi
				done <<<"${COMPONENT_BASE}:"

				local_script="${COMPONENT_BASE%%:*}/${abs_component}.sh"
				if [[ "$COMPONENT_BASE_URL" = "-" ]]; then
					continue
				else
					component debug "ACQUIRE: ${abs_component}"

					if [[ ! -d "${component_dir}" ]]; then
						component debug "MKDIR: $component_dir"
						if ! mkdir -p "${component_dir}"; then
							component debug "MKDIR: $component_dir [FAILED]"
							return 1
						fi
					fi

					local component_dir="$(dirname "${local_script}")"
					local base_url
					while read -r -d ' ' base_url; do
						[[ -z "$base_url" ]] && continue
						local url="${base_url%/}/${abs_component}.sh"
						component debug "ACQUIRE[URL]: ${url}"
						
						if curl -f -s -o "${local_script}" "${url}"
						then
							chmod a+x "${local_script}" || return 1
							return 0
						else
							component debug "ACQUIRE[URL]: ${url} [FAILED]"
							continue
						fi
					done <<<"${COMPONENT_BASE_URL} "

					component debug "ACQUIRE: $abs_component [FAILED]"
				fi
			done <<<"${COMPONENT_PREFIX}::"
			
			component debug "ACQUIRE: No match for ${component} [FAILED]"
			return 1
			;;
		register-script)
			local script="$1"
			local component=
			local base=
			local candidate=
			local longest=
			while read -r -d ':' base; do
				candidate="${script#$base}"
				[[ "${candidate}" = "${script}" ]] && continue

				[[ ${#candidate} -gt ${#longest} ]] && longest="$candidate"
			done <<<"${COMPONENT_BASE}"

			component="${longest%.sh}"
			component="${component#/}"

			component register "$component"
			;;
		register)
			local component="$1"
			
			component debug "CONFIRMED: $component"
			printf '%s\n' "$component" \
				>> "${COMPONENT_REGISTRY}"
			;;
		check)
			local component="$1"
			local abs_component=
			local prefix
			local did_empty=0
			while read -r -d : prefix; do
				if [[ -z "$prefix" ]]; then
					[[ "$did_empty" = "1" ]] && continue
					did_empty=1
				fi

				abs_component="$prefix/$component"
				abs_component="${abs_component#/}"
				abs_component="$(component expand "$abs_component")"

				if [[ "${COMPONENT_ALREADY/;$abs_component;/;}" != "${COMPONENT_ALREADY}" ]]
				then
					return 0
				fi

				[[ -r "${COMPONENT_REGISTRY}" ]] || continue
				if \
					grep -q -F -x \
						-e "$abs_component" \
						"${COMPONENT_REGISTRY}"
				then
					return 0
				fi
			done <<<"${COMPONENT_PREFIX}::"
			return 1
			;;
		tempdir)
			local var="$1"
			[[ -z "$var" ]] && var=COMPONENT_TEMPDIR

			local TEMP="$(mktemp --tmpdir -d 'component.XXXXXXXXXX')"
			if [ -n "$TEMP" -a -d "$TEMP" -a -w "$TEMP" ]; then
				printf \
	'%q=%q; _component_tempdir(){ rm -rf "${%q}"; }; trap _component_tempdir EXIT' \
	"$var" "$TEMP" "$var"
				return 0
			fi

			printf "Failed to create temporary directory\n" >&2
			printf 'exit 1'
			return 1
			;;
	esac
}

component-require(){
	local component="$1"

	if component check "$component"; then
		return 0
	fi

	component debug "REQUIRE: $component"

	local component_script="$(component acquire "$component")"
	[[ -n "$component_script" ]] || return 1

	if \
		COMPONENT_INDENT="$COMPONENT_INDENT  " \
		COMPONENT_ALREADY="${COMPONENT_ALREADY%;};${component};" \
		"${component_script}"
	then
		component register-script "$component_script"
		return 0
	fi

	component debug "REQUIRE: $component [FAILED]"
	return 1
}

component init
