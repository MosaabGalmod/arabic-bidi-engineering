#!/usr/bin/env bash
# install/antigravity.sh - Install arabic-bidi-engineering skill for Antigravity
#
# Usage:
#   bash antigravity.sh             # install
#   bash antigravity.sh --uninstall # remove skill directory and GEMINI.md block
#
# Requires: bash, npx (Node.js), awk

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SKILL_NAME="arabic-bidi-engineering"
SKILL_REPO="MosaabGalmod/${SKILL_NAME}"
MARKER_START="<!-- arabic-bidi-engineering:start -->"
MARKER_END="<!-- arabic-bidi-engineering:end -->"
GEMINI_DIR="${HOME}/.gemini"
GEMINI_FILE="${GEMINI_DIR}/GEMINI.md"
AGENTS_SKILL_DIR="${HOME}/.agents/skills/${SKILL_NAME}"
CONFIG_SKILL_DIR="${GEMINI_DIR}/config/skills/${SKILL_NAME}"
LEGACY_SKILL_DIR="${GEMINI_DIR}/antigravity/skills/${SKILL_NAME}"

# ---------------------------------------------------------------------------
# Block content (same text as the PowerShell script)
# ---------------------------------------------------------------------------
BLOCK_CONTENT="${MARKER_START}
## Arabic output (arabic-bidi-engineering)

- Before writing ANY Arabic text (chat replies, Markdown, documents, UI strings, generated files), load the \`arabic-bidi-engineering\` skill and follow it; for chat replies apply its Section 0 fully.
- In the Antigravity app chat panel, apply Section 0 rule 9: wrap every Arabic chat reply in \`<div dir=\"rtl\">\` with a blank line after the opening tag and before \`</div>\`; keep fenced code blocks outside the div.
- In terminal agents that do not render HTML (e.g. Gemini CLI), do not add the div wrapper.
- For Word/Excel/PDF/HTML deliverables, follow the skill's references and run its checker (\`scripts/check_arabic_text.py\`) before delivery.
${MARKER_END}"

# ---------------------------------------------------------------------------
# Helper: safely remove directory or symlink without touching target contents
# ---------------------------------------------------------------------------
remove_dir_safely() {
    local target="$1"
    if [ -L "${target}" ]; then
        rm "${target}"
    elif [ -d "${target}" ]; then
        rm -rf "${target}"
    fi
}

# ---------------------------------------------------------------------------
# Helper: check marker validity in GEMINI.md
# Returns: 'none', 'valid', or 'corrupted'
# ---------------------------------------------------------------------------
check_markers() {
    if [ ! -f "${GEMINI_FILE}" ]; then
        echo "none"
        return 0
    fi

    local start_count end_count
    start_count=$(grep -cF "${MARKER_START}" "${GEMINI_FILE}" 2>/dev/null || true)
    end_count=$(grep -cF "${MARKER_END}" "${GEMINI_FILE}" 2>/dev/null || true)

    if [ "${start_count}" -eq 0 ] && [ "${end_count}" -eq 0 ]; then
        echo "none"
        return 0
    fi

    if [ "${start_count}" -eq 1 ] && [ "${end_count}" -eq 1 ]; then
        local start_line end_line
        start_line=$(grep -nF "${MARKER_START}" "${GEMINI_FILE}" | cut -d: -f1)
        end_line=$(grep -nF "${MARKER_END}" "${GEMINI_FILE}" | cut -d: -f1)
        if [ "${start_line}" -lt "${end_line}" ]; then
            echo "valid"
            return 0
        fi
    fi

    echo "corrupted"
    return 0
}

# ---------------------------------------------------------------------------
# UNINSTALL path
# ---------------------------------------------------------------------------
do_uninstall() {
    echo "Removing GEMINI.md rule block for ${SKILL_NAME} ..."
    if [ -f "${GEMINI_FILE}" ]; then
        local marker_state
        marker_state=$(check_markers)
        if [ "${marker_state}" = "corrupted" ]; then
            echo "ERROR: Corrupted or unbalanced markers found in ${GEMINI_FILE}. Please fix GEMINI.md manually." >&2
            exit 1
        fi
        if [ "${marker_state}" = "valid" ]; then
            local tmp_file
            tmp_file=$(mktemp "${GEMINI_DIR}/GEMINI.tmp.XXXXXX")
            trap 'rm -f "${tmp_file:-}"' EXIT

            awk -v start="${MARKER_START}" -v end="${MARKER_END}" '
            BEGIN { in_block=0; has_prev=0; prev="" }
            {
                if (index($0, start) > 0) {
                    in_block = 1
                    if (has_prev) {
                        temp = prev
                        gsub(/[ \t\r]/, "", temp)
                        if (temp != "") {
                            print prev
                        }
                        has_prev = 0
                    }
                    next
                }
                if (index($0, end) > 0) {
                    in_block = 0
                    next
                }
                if (in_block) {
                    next
                }
                if (has_prev) {
                    print prev
                }
                prev = $0
                has_prev = 1
            }
            END {
                if (has_prev && !in_block) {
                    print prev
                }
            }
            ' "${GEMINI_FILE}" > "${tmp_file}"

            mv "${tmp_file}" "${GEMINI_FILE}"
            trap - EXIT
            echo "  Removed rule block from ${GEMINI_FILE}."
        else
            echo "  Marker not found in ${GEMINI_FILE} - nothing to remove."
        fi
    else
        echo "  ${GEMINI_FILE} does not exist - nothing to remove."
    fi

    echo "Removing Antigravity skill directories ..."
    remove_dir_safely "${CONFIG_SKILL_DIR}"
    remove_dir_safely "${LEGACY_SKILL_DIR}"
    echo "  Removed Antigravity skill directories."

    echo ""
    echo "Done. To also remove the installed skill run:"
    echo "  npx skills remove ${SKILL_NAME} -g -a antigravity"
    exit 0
}

# ---------------------------------------------------------------------------
# INSTALL path
# ---------------------------------------------------------------------------
mirror_skill_dir() {
    local src="$1"
    local dest="$2"
    if [ "${src}" != "${dest}" ]; then
        remove_dir_safely "${dest}"
        mkdir -p "${dest}"
        cp -R "${src}/." "${dest}/"
    fi
}

do_install() {
    # 1. Check for npx
    echo "Checking for npx ..."
    if ! command -v npx >/dev/null 2>&1; then
        echo "ERROR: 'npx' not found. Please install Node.js (https://nodejs.org) and ensure it is on PATH." >&2
        exit 1
    fi
    echo "  npx found: $(command -v npx)"

    # 2. Run skills CLI
    echo ""
    echo "Installing skill via skills CLI ..."
    npx -y skills add "${SKILL_REPO}" -g -a antigravity --copy -y

    # 3. Locate installed source directory
    echo ""
    echo "Locating installed skill ..."
    local source_dir=""
    if [ -f "${AGENTS_SKILL_DIR}/SKILL.md" ]; then
        source_dir="${AGENTS_SKILL_DIR}"
    elif [ -f "${CONFIG_SKILL_DIR}/SKILL.md" ]; then
        source_dir="${CONFIG_SKILL_DIR}"
    elif [ -f "${LEGACY_SKILL_DIR}/SKILL.md" ]; then
        source_dir="${LEGACY_SKILL_DIR}"
    else
        echo "ERROR: Expected SKILL.md not found in ${AGENTS_SKILL_DIR}, ${CONFIG_SKILL_DIR}, or ${LEGACY_SKILL_DIR}." >&2
        exit 1
    fi
    echo "  Found source skill at: ${source_dir}"

    # 4. Mirror to Antigravity directories
    echo "  Mirroring skill to Antigravity directories ..."
    mirror_skill_dir "${source_dir}" "${CONFIG_SKILL_DIR}"
    mirror_skill_dir "${source_dir}" "${LEGACY_SKILL_DIR}"

    if [ ! -f "${CONFIG_SKILL_DIR}/SKILL.md" ]; then
        echo "ERROR: Expected file not found after mirror: ${CONFIG_SKILL_DIR}/SKILL.md" >&2
        exit 1
    fi
    echo "  Verified: ${CONFIG_SKILL_DIR}/SKILL.md"

    # 5. Upsert GEMINI.md block
    echo ""
    echo "Updating ${GEMINI_FILE} ..."
    mkdir -p "${GEMINI_DIR}"

    local marker_state
    marker_state=$(check_markers)
    if [ "${marker_state}" = "corrupted" ]; then
        echo "ERROR: Corrupted or unbalanced markers found in ${GEMINI_FILE}. Please fix GEMINI.md manually." >&2
        exit 1
    fi

    local tmp_file
    tmp_file=$(mktemp "${GEMINI_DIR}/GEMINI.tmp.XXXXXX")
    trap 'rm -f "${tmp_file:-}"' EXIT

    if [ "${marker_state}" = "valid" ]; then
        # Replace existing block in-place
        export BLOCK_CONTENT
        awk -v start="${MARKER_START}" -v end="${MARKER_END}" '
        BEGIN { in_block=0 }
        index($0, start) > 0 {
            in_block = 1
            print ENVIRON["BLOCK_CONTENT"]
            next
        }
        index($0, end) > 0 {
            in_block = 0
            next
        }
        !in_block { print }
        ' "${GEMINI_FILE}" > "${tmp_file}"
        mv "${tmp_file}" "${GEMINI_FILE}"
        trap - EXIT
        echo "  Updated existing rule block in ${GEMINI_FILE}."
    else
        # State is 'none': append block with a preceding blank line
        if [ -s "${GEMINI_FILE}" ]; then
            cp "${GEMINI_FILE}" "${tmp_file}"
            res=$(tail -c 1 "${GEMINI_FILE}" 2>/dev/null; printf x)
            last_char="${res%x}"
            if [ "${last_char}" != $'\n' ]; then
                printf '\n' >> "${tmp_file}"
            fi
            printf '\n%s\n' "${BLOCK_CONTENT}" >> "${tmp_file}"
        else
            printf '%s\n' "${BLOCK_CONTENT}" > "${tmp_file}"
        fi
        mv "${tmp_file}" "${GEMINI_FILE}"
        trap - EXIT
        echo "  Appended rule block to ${GEMINI_FILE}."
    fi

    # 6. Done
    echo ""
    echo "Installation complete."
    echo "  Skill  : ${CONFIG_SKILL_DIR}/SKILL.md"
    echo "  Rule   : ${GEMINI_FILE}"
    echo ""
    echo "Restart Antigravity to pick up the new skill and rule."
    echo "Note: to update the skill later, re-run this installer."
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
case "${1:-}" in
    --uninstall) do_uninstall ;;
    "")          do_install   ;;
    *)
        echo "Usage: $0 [--uninstall]" >&2
        exit 1
        ;;
esac
