import type { Register } from 'claude-code'

const fg = ([r, g, b]: number[]) => `\x1b[38;2;${r};${g};${b}m`
const LAVENDER = fg([180, 190, 254])
const BLUE = fg([137, 180, 250])
const GRAY = fg([108, 112, 134])
const RESET = '\x1b[0m'

export const register: Register = on => {
  on('ui.render', { component: 'AgentRow' }, ($, e, next) => {
    const { label, name, type, model } = e.props
    if (!model) return next(e)
    const title = label || name || type
    const body = title ? `${LAVENDER}${title} ${GRAY}· ${BLUE}${model}${RESET}` : `${BLUE}${model}${RESET}`
    return next({ ...e, props: { ...e.props, body } })
  })
}
