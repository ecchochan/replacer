#cython: language_level=3, boundscheck=False, wraparound=False, nonecheck=False, cdivision=True
import re
from itertools import product



cdef int MODE_CHAR     = 0
cdef int MODE_ENUM     = 1
cdef int MODE_ENUM_OPT = 2
cdef int MAX_SUB       = 100
SUB_SYMBOLS = tuple(['\\%s'%(i+1) for i in range(MAX_SUB)])

class Replacer():
    def __init__(self, mapping_wf_exception):
        cdef int i
        cdef bint optional
        
        mapping_single = ({}, False, ())

        for k, v in mapping_wf_exception.items():
            this = mapping_single
            if re.search(r'\[(.*?)\]', k):
                bucket = []

                splitted = re.split(r'\[(.*?)\]', k)

                i = 1
                for seg in splitted[1:]:
                    i += 1
                    if i%2 == 1:
                        for s in seg:
                            bucket.append((MODE_CHAR, s,))
                    else:
                        optional = seg.endswith('?')
                        if optional:
                            seg = seg[:len(seg)-1]

                        digit_range = re.search(r'(\d)\-(\d)', seg)

                        if digit_range:
                            a = int(digit_range.group(1))
                            b = int(digit_range.group(2))
                            seg = '|'.join((str(_) for _ in range(a, b+1)))

                        se = {}
                        for e in seg.split('|'):
                            if e[0] not in se:
                                se[e[0]] = []


                            se[e[0]].append(e[1:] or None)


                        bucket.append((MODE_ENUM_OPT if optional else MODE_ENUM, se,))

                regx = (bucket, v)
                
                temp = splitted[0]

                if temp:
                    for c in temp[:len(temp)-1]:
                        if c not in this[0]:
                            this[0][c] = this = ({}, None, ())
                        else:
                            this = this[0][c]

                    c = temp[len(temp)-1]

                    if c not in this[0]:
                        this[0][c] = ({}, None, (regx,))
                    else:
                        this[0][c] = this[0][c][:2] + (this[0][c][2]+(regx,),)
                else:
                    mapping_single = mapping_single[0][c][:2] + (mapping_single[0][c][2]+(regx,),)


                continue
            for c in k[:len(k)-1]:
                if c not in this[0]:
                    this[0][c] = this = ({}, None, ())
                else:
                    this = this[0][c]

            THIS = this
            repl, a, b = v

            A = ({}, False, ())

            for e in a:
                this = A
                for c in reversed(e[1:]):
                    if c not in this[0]:
                        this[0][c] = this = ({}, False, ())
                    else:
                        this = this[0][c]

                cc = e[0]
                if cc not in this[0]:
                    this[0][cc] = ({}, True, ())
                else:
                    this[0][cc] = (this[0][cc][0], True, this[0][cc][2])

            B = ({}, False, ())
            for e in b:
                this = B
                for c in e[:len(e)-1]:

                    if c not in this[0]:
                        this[0][c] = this = ({}, False, ())
                    else:
                        this = this[0][c]

                cc = e[len(e)-1]
                if cc not in this[0]:
                    this[0][cc] = ({}, True, ())
                else:
                    this[0][cc] = (this[0][cc][0], True, this[0][cc][2])

            temp = k[len(k)-1]
            if temp not in THIS[0]:
                THIS[0][temp] = ({}, (repl, A, B), ())
            else:
                THIS[0][temp] = (THIS[0][temp][0], (repl, A, B), THIS[0][temp][2])
                

        self.mapping_single = mapping_single = mapping_single[0]
                
    def translate(self, text):
        cdef int pos, max_length, min_length, i, I, L, LL, u, U, n, l, j, lvl, REPL_pos = -1
        cdef bint ok = False, abort
        cdef str c
                          
        mapping_single = self.mapping_single
        text = text + ' '

        bucket = []

        pos = -1
        last_char = None
        last_char2 = None
        texts = text
        max_length = len(text) - 1


        while pos < max_length:
            pos += 1
            c = texts[pos]
            if not c.strip():
                bucket.append(c)
                continue
            last_char

            repl_found = False

            i = pos
            C = c
            mapping = mapping_single
            REPL = None
            #print(i, c, c in mapping)
            while C in mapping:
                mapping, repl, regx = mapping[C]
                #print(C, repl, regx, mapping.keys())
                if regx:
                    I = i
                    sub = None
                    L = 0
                    for rs, _repl in regx:
                        _repl = _repl[0]
                        i = I + 1
                        sub = []
                        C = texts[i]
                        for mode, compare in rs:
                            ok = False
                            #print('::', '[%s]'%mode, C, compare, )
                            if mode == MODE_CHAR:
                                if compare == C:
                                    ok = True

                            else:
                                if C in compare:
                                    cont = compare[C]
                                    ok = True
                                    LL = 0
                                    U = 0
                                    CON = None
                                    #print('!!', cont, C)
                                    for con in cont:
                                        u = i + 1
                                        if con is None and CON is None:
                                            CON = C
                                            U = u
                                            continue
                                        for e in con:
                                            ok = False
                                            CC = texts[u]
                                            if CC != e:
                                                break
                                            u = u + 1
                                            ok = True
                                        if ok:
                                            l = len(con)
                                            if CON is None or l > LL:
                                                CON = C + con
                                                LL = l
                                                U = u

                                    if CON:
                                        #print('>>', CON)
                                        sub.append(CON)
                                        i = U - 1
                                    else:
                                        sub.append('')

                                elif mode == MODE_ENUM_OPT:
                                    sub.append('')
                                    ok = True
                                    continue

                            #print(sub)
                            if ok:
                                i += 1
                                if i > max_length:
                                    ok = False
                                    break
                                C = texts[i]
                            else:
                                break

                        if ok:
                            for n in range(10):
                                ss = SUB_SYMBOLS[n]
                                if ss not in _repl:
                                    break
                                _repl = _repl.replace(ss, sub[n])

                            l = len(_repl)
                            if l > L:
                                L = l
                                REPL = _repl
                                REPL_pos = i - 1

                    if REPL is None:
                        i = I
                    else:

                        break



                if repl is not None:
                    repl, exceptions_before, exceptions_after = repl

                    abort = False

                    I = i

                    i = i + 1
                    if i <= max_length:
                        C = texts[i]
                        this, end, _regx = exceptions_after
                        while C in this:
                            this, end, _regx = this[C]
                            if end:
                                abort = True
                                break
                            i = pos + 1
                            if i > max_length:
                                break
                            C = texts[i]

                    if abort:
                        i = I + 1
                        if i > max_length:
                            break
                        C = texts[i]
                        continue

                    i = pos - 1
                    if i >= 0:
                        C = texts[i]
                        this, end, _regx = exceptions_before
                        while C in this:
                            this, end, _regx = this[C]
                            if end:
                                abort = True
                                break
                            i = pos - 1
                            if i < 0:
                                break
                            C = texts[i]



                    if abort:
                        i = I + 1
                        if i > max_length:
                            break
                        C = texts[i]
                        continue
                    #print(pos, I)
                    for j in range(pos, I+1):
                        C = texts[j]
                        min_length = I - j + 1  #   [10 ~ 13]
                        _mapping = mapping_single
                        lvl = 0
                        while C in _mapping:
                            _mapping, _repl, _regx = _mapping[C]

                            # better guess ?
                            if _regx:
                                print(_regx)
                                pass

                            lvl += 1
                            if _repl is not None:
                                if lvl > min_length:
                                    abort = True
                                    break

                            j += 1
                            if j > max_length:
                                break
                            C = texts[j]


                        if abort:
                            break

                    if abort:
                        i = I + 1
                        if i > max_length:
                            break
                        C = texts[i]
                        continue


                    REPL = repl
                    REPL_pos = I

                    i = I


                i += 1
                if i > max_length:
                    break
                C = texts[i]

            if REPL is not None:
                bucket.append(REPL)
                pos = REPL_pos

                continue

            bucket.append(c)
            
        ret = ''.join(bucket)
            
        return ret[:len(ret)-1]
