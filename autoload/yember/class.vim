let s:types = [ 'Route', 'Controller', 'Model', 'Service', 'Mixin', 'Component', 'Helper' ]

let s:regex = '\v^(\s*)?export default .{-}('.join(s:types, '|').')\.(extend|create|helper)\((.{-})?[, ]*[\{\)]'

function! yember#class#Init()
	return {
		\ 'is_match': function('yember#class#IsMatch'),
		\ 'parse_data': function('yember#class#ParseData'),
		\ 'template': 'class.tpl'
	\ }
endfunction

function! yember#class#IsMatch(text)
	return (match(a:text, s:regex) > -1)
endfunction

function! yember#class#ParseData(text)

	let l:matches = matchlist(a:text, s:regex)

	let l:data = {}
	let l:data["indent"] = l:matches[1]
	if l:matches[4] != '' && l:matches[2] != 'Helper'
		" there is no @uses tag for Helper
		let l:data["uses"] = s:ParseUses(l:matches[4])
	endif

	let l:parts = split(expand('%:p:r'), '/')

	" find namespace's starting index
	let l:start = 1
	for l:part in l:parts
		if l:part == 'app'
			break
		endif
		let l:start += 1
	endfor

	" get only the parts relevant to namespace and class
	let l:parts = l:parts[l:start:]

	" determine class
	let l:classOffset = -1
	" if class name is one of generic name, use directory's name for class
	if index(['component', 'route', 'controller'], l:parts[-1]) != -1
		let l:classOffset = -2
	endif
	let l:class = l:parts[l:classOffset]

	" determine namespace
	let l:namespace = [l:matches[2]]
	let l:namespaceOffset = l:classOffset - 1
	" check if dir structure needs to be in namespace and append if yes
	if len(l:parts[:l:namespaceOffset]) > 0
		let l:namespace = l:namespace + l:parts[:l:namespaceOffset]
	endif

	" determine extends
	let l:extends = l:matches[2]
	if index(['Route', 'Controller', 'Component', 'Service', 'Helper'], l:extends) != -1
		let l:data['extends'] = 'Ember.' . l:extends
	elseif index(['Model'], l:extends) != -1
		let l:data['extends'] = 'DS.' . l:extends
	endif

	let l:data['class'] = s:ConvertDashedToTitleCased(l:class)
	let l:data['namespace'] = s:ConvertToNamespace(l:namespace)

	return l:data

endfunction

" Parses and generates a list of @uses
function! s:ParseUses(text)
	
	let l:parts = split(a:text, ',')
	let l:parts =  yember#util#TrimList(l:parts)
	
	let l:ret = []
	for l:part in l:parts
		call add(l:ret, {'item': 'Mixin.' . l:part})
	endfor

	return l:ret

endfunction

" Converts dashed-name into DashedName in TitleCased
function! s:ConvertDashedToTitleCased(str)

	let l:ret = []

	let l:parts = split(a:str, '-')
	for l:part in l:parts
		let l:upperCased = substitute(l:part, '\v(\k)(\k*)', '\u\1\2', '')
		call add(l:ret, l:upperCased)
	endfor

	return join(l:ret, '')
	
endfunction

" Converts a list of parts into namespace string
function! s:ConvertToNamespace(parts)

	let l:ret = []

	for l:part in a:parts
		" don't include dir names for the ones that don't follow convention
		if index(['helpers'], l:part) == -1
			call add(l:ret, s:ConvertDashedToTitleCased(l:part))
		endif
	endfor

	return join(l:ret, '.')

endfunction
