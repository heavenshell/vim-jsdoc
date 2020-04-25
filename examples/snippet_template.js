const generateSnippetMark = (i) => {
  return '<`' + i + ':description`>'
}

const formatParam = (param, i) => {
  if (param.alias) {
    if (param.name) {
      return `{${param.alias}} ${param.name} - ` + generateSnippetMark(i++)
    }
    return param.alias
  }

  if (param.name) {
    return `{${param.type}} ${param.name} - ` + generateSnippetMark(i++)
  }
  return `{${param.type}}`
}

const generateClassDoc = (doc) => {
  const d =
    doc.heritageClauses.length === 0
      ? `
/**
 * ` + '<`0:name`>' + `
 */`
      : `
/**
 * ` + '<`0:name`>' + `
 *
 * @${doc.heritageClauses.map((h) => `${h.type} ${h.value}`).join('\n * @')}
 */`

  return d.trim()
}

module.exports = {
  generateClassDoc,
  generateInterfaceDoc: generateClassDoc,
  generatePropertyDoc: (doc) => {
    return `
/**
 * @type {${doc.returnType}}
 */`.trimLeft()
  },
  generateFunctionDoc: (doc) => {
    const start =
      doc.params.length === 0
        ? `
/**
 * ` + '<`0:name`>'
        : `
/**
 * ` + '<`0:name`>' + `
 *
 * @param ${doc.params.map(formatParam).join('\n * @param ')}`

    const delimiter =
      doc.params.length === 0 && doc.returnType !== ''
        ? `
 *`
        : ``

    const end = doc.returnType
      ? `
 * @returns {${doc.returnType}} ` + '<`0:return value`>' + `
 */`
      : `
 */`
    return `${start.trimLeft()}${delimiter}${end.trimRight()}`
  },
}
