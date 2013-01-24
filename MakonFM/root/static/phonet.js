var Phonet = {
    tbl_to_human: {
        a: 'a', aa: 'á',
        b: 'b',
        c: 'c', ch: 'č',
        d: 'd', dj: 'ď',
        e: 'e', ee: 'é',
        f: 'f',
        g: 'g',
        h: 'h',
        i: 'i', ii: 'í', j: 'j',
        k: 'k',
        l: 'l',
        m: 'm',
        n: 'n', ng: 'n', nj: 'ň',
        o: 'o', ow: 'ou',
        p: 'p',
        r: 'r', rsh: "ř'", rzh: 'ř',
        s: 's', sh: 'š',
        t: 't', tj: 'ť',
        u: 'u', uu: 'ú',
        v: 'v',
        x: 'ch',
        y: 'y', yy: 'ý',
        z: 'z', zh: 'ž',
        sil: '', sp: ''
    },
    tbl_from_human: {
        'a': 'a', 'á': 'aa',
        'b': 'b',
        'c': 'c', 'č': 'ch',
        'd': 'd', 'ď': 'dj',
        'e': 'e', 'é': 'ee',
        'f': 'f',
        'g': 'g',
        'h': 'h', 'ch': 'x',
        'i': 'i', 'í': 'ii', 'j': 'j',
        'k': 'k',
        'l': 'l',
        'm': 'm',
        'n': 'n', 'ng': 'ng', 'ň': 'nj',
        'o': 'o', 'ou': 'ow',
        'p': 'p',
        'r': 'r', 'ř': 'rzh', "ř'": 'rsh',
        's': 's', 'š': 'sh',
        't': 't', 'ť': 'tj',
        'u': 'u', 'ú': 'uu', 'ů': 'uu',
        'v': 'v', 'w': 'v',
        'y': 'i', 'ý': 'ii',
        'z': 'z', 'ž': 'zh'
    },
    to_human: function(phon) {
        var rv = {
            sp_after: true,
            sil_after: false,
            str: ''
        };
        if (!phon) { return ''; }
        var phones = phon.split(/\s+/);
        for (var i = 0; i < phones.length; i++) {
            var phone = phones[i];
            var lookahead = phones[i+1];
            var lookbehind = phones[i-1];
            if (phone === 'sp') {
                sil_after = false;
                sp_after = true;
            }
            if (phone === 'sil') {
                sil_after = true;
                sp_after = false;
            }
            if (({d:1,t:1,n:1})[lookbehind]) {
                if (phone === 'i') {
                    phone = 'y';
                }
                if (phone === 'ii') {
                    phone = 'yy';
                }
            }
            
            if (!(phone in Phonet.tbl_to_human)) { return; }
            rv.str += Phonet.tbl_to_human[phone];
            
            if (phone === 'o' && lookahead === 'u') {
                rv.str += "'";
            }
            if (phone === 'c' && lookahead === 'h') {
                rv.str += "'";
            }
        }
        return rv;
    },
    from_human: function(human_raw, opt) {
        if (!opt) { opt = { sp_after: true }; }
        var rv = [];
        var human = human_raw
        .toLowerCase()
        .replace('x', 'ks', 'g')
        .replace('q', 'kv', 'g')
        .replace(/([bfpv])ě/g, '$1je')
        .replace('dě', 'ďe', 'g')
        .replace('tě', 'ťe', 'g')
        .replace('ně', 'ňe', 'g')
        .replace('di', 'ďi', 'g')
        .replace('ti', 'ťi', 'g')
        .replace('ni', 'ňi', 'g')
        .replace('dí', 'ďí', 'g')
        .replace('tí', 'ťí', 'g')
        .replace('ní', 'ňí', 'g');
        
        for (var i = 0; i < human.length; i++) {
            var chr = human[i];
            var lookahead = human[i+1];
            var lookbehind = human[i-1];
            
            if (chr === "'") {
                if (lookbehind === 'o' && lookahead === 'u') {
                    continue;
                }
                if (lookbehind === 'c' && lookahead === 'h') {
                    continue;
                }
            }
            if (chr === 'c' && lookahead === 'h') {
                chr = 'ch';
                i++;
                lookahead = human[i+1];
            }
            if (chr === 'o' && lookahead === 'u') {
                chr = 'ou';
                i++;
                lookahead = human[i+1];
            }
            if (chr === 'ř' && lookahead === "'") {
                chr = "ř'";
                i++;
                lookahead = human[i+1];
            }
            
            if (chr === 'n' && ({g:1,k:1})[lookahead]) {
                chr = 'ng';
            }
            if (chr === 'ř') {
                if (i === human.length-1) {
                    chr = "ř'";
                }
                else if (({p:1,t:1,ť:1,k:1,s:1,š:1,c:1,č:1,f:1})[lookbehind]) {
                    chr = "ř'";
                }
                else if (lookbehind === 'h' && human[i-2] === 'c') {
                    chr = "ř'";
                }
                else if (({p:1,t:1,ť:1,k:1,s:1,š:1,c:1,č:1,f:1})[lookahead]) {    // zahrnuje 'ch' zprava
                    chr = "ř'";
                }
                else if (i === human.length-2) {
                    if (({b:1,d:1,ď:1,g:1,z:1,ž:1,h:1})[lookahead]) {
                        chr = "ř'";
                    }
                }
            }
            if (!(chr in Phonet.tbl_from_human)) {
                throw "Unknown character '"+chr+"'"
            }
            rv.push(Phonet.tbl_from_human[chr]);
        }
        if (opt.sp_after) {
            rv.push('sp');
        }
        else if (opt.sil_after) {
            rv.push('sil');
        }
        return rv.join(' ');
    }
};
