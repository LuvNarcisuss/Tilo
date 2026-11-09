"""Verify editorial tutorials through YouTube's official oEmbed service."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json, subprocess

ROOT = Path(__file__).resolve().parents[1]
VIDEOS = ['lWaBh-r2ZP0','eJLA2RlZNq4','iM_KMYulI_s','1-SJGQ2HLp8','6OBoHKRQdHI','cdjcz73EEtc','LrKhcvZYFdQ','vLP2CXsQGGo','bJeUb8ToRIw','Q3xg35pcLyo','OMqQjB4pJVY','zyF_0hqLqHA']

def verify(item):
    index, video = item
    watch = 'https://www.youtube.com/watch?v=' + video
    result = subprocess.run(['curl','--silent','--show-error','--fail','--location','--retry','2','--retry-all-errors','--max-time','20','https://www.youtube.com/oembed?url=' + watch + '&format=json'],check=True,capture_output=True,text=True)
    metadata = json.loads(result.stdout)
    assert metadata['type'] == 'video' and video in metadata['html']
    return {'recipeID':f'recipe-{index:02d}','tutorial':{'videoID':video,'title':metadata['title'],'author':metadata['author_name'],'sourceURL':watch,'provider':'YouTube','note':"A creator's take on this dish. Ingredients and timings may differ from Tilo's recipe."},'verifiedAt':'2026-11-05','verification':'Official oEmbed returned a video, title, author and embed URL.','oembed':metadata}

if __name__ == '__main__':
    with ThreadPoolExecutor(max_workers=4) as pool:
        rows = list(pool.map(verify,enumerate(VIDEOS,1)))
    output = ROOT/'docs/recipe-tutorials.json'
    output.write_text(json.dumps(rows,indent=2,ensure_ascii=True)+'\n')
    print(json.dumps([{'recipeID':r['recipeID'],'title':r['tutorial']['title'],'author':r['tutorial']['author']} for r in rows],indent=2))
