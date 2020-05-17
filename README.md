# replacer
A simple string translate, like regex, but matching multiple patterns


```bash
sudo pip3 install -U git+https://github.com/ecchochan/replacer.git

```

# Usage

```python
from replacer import Replacer

mapping_wf_exception = {
    '為什麼':(         # match 為什麼
        
        '點解',        # replace with 點解
        
        '認以難設改訂' # not preceded by these characters
        '減增定略喻因'
        '行視較稱分視'
        '行即作變約能'
        '降定轉淪化作行',  
        
        '麼'          # not followed by these characters
    ),
    '這[個?]樣子':( # optional 個
        '咁嘅樣',
        '',
        ''
    ),
    '的腳昨[天|日]扭傷了':(  # OR for 天 and 日
        '隻腳琴日拗柴',
        '',
        ''
    ),
    '的腳[今|前][天|日]扭傷了':(  # OR for (今,前) and (天,日)
        '隻腳\\1日拗柴',         # replace with 隻腳 {1} 日拗柴 
                                # where {n} is substitute by 
                                # the n th bracket
        '',
        ''
    ),
    '出生於[1-9][百|千|萬|億?]年[之前|之前|前|後?]':(
        '喺\\1\\2年\\3出世',
        '',
        ''
    )
}

repl = Replacer(mapping_wf_exception)

text = '''

為什麼呢?

他認為什麼呢?

這樣不行

這樣子不行

我的腳前天扭傷了'''

text = repl.translate(text)
print(text)

assert text == '''

點解呢?

他認為什麼呢?

這樣不行

咁嘅樣不行

我隻腳前日拗柴'''


```

# Benchmark


```python
from replacer import Replacer

import random, string
from time import time

import os
import psutil
process = psutil.Process(os.getpid())


get_memory_in_MB = lambda : process.memory_info().rss / 1024 / 1024
print_memory = lambda : print('memory in use: %.1f MB'%get_memory_in_MB())

print_memory()
print()


chars = string.ascii_uppercase + string.digits
n = 10
n1 = 5
n2 = 5

mapping = {}

for i in range(100000):

    k = ''.join(random.choices(chars, k=n))
    v = (
        'sth',
        ''.join(random.choices(chars, k=n1)),
        ''.join(random.choices(chars, k=n2))
    )
    
    mapping[k] = v
    

print_memory()
print()
    
from time import time
t0 = time()
repl = Replacer(mapping)
dt = time() - t0

print('loaded %s patterns in %.6f s.'%(len(mapping), dt))
print()
print_memory()
print()


for N in (100,1000,10000, 100000, 1000000):
    text = ''.join(random.choices(chars, k=N))
    
    bucket = []
    for i in range(10):
        t0 = time()
        repl.translate(text)
        dt = time() - t0
        bucket.append(dt)
    
    print('%-10d chars : %.7f s'%(N, sum(bucket) / len(bucket)))

```

```
>>
memory in use: 43.9 MB

memory in use: 73.0 MB

loaded 100000 patterns in 2.566002 s.

memory in use: 651.5 MB

100        chars : 0.0000260 s
1000       chars : 0.0002596 s
10000      chars : 0.0032442 s
100000     chars : 0.0383852 s
1000000    chars : 0.3740452 s

```