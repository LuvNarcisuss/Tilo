"""Create Tilo's original recipe seed; no third-party recipe prose is copied."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IDENTITY = json.loads((ROOT/'TiloApp/Configuration/Identity.json').read_text())
ORIGIN = 'https://' + IDENTITY['backendProjectRef'] + '.supabase.co/storage/v1/object/public/toli-catalog'

def ingredient(name, quantity, unit):
    return dict(name=name, quantity=str(quantity), unit=unit)

def recipe(index, title, cuisine, prep, cook, servings, summary, ingredients, steps, tags):
    return dict(id=f'recipe-{index:02}', title=title, category=cuisine,
                image_url=f'{ORIGIN}/recipe-{index:02}.jpg',
                payload=dict(summary=summary, prepMinutes=prep, cookMinutes=cook,
                             servings=servings, calories=0, protein=0, carbs=0, fat=0,
                             difficulty='Easy' if cook <= 30 else 'Weekend project',
                             ingredients=[ingredient(*i) for i in ingredients], steps=steps, tags=tags))

RECIPES = [
recipe(1, 'Tomato & basil spaghetti', 'Italian', 10, 20, 2,
       'A bright, silky tomato sauce and a generous handful of fresh basil. Your weeknight pasta ritual.',
       [('Spaghetti',200,'g'),('Cherry tomatoes',350,'g'),('Garlic cloves',2,''),('Olive oil',2,'tbsp'),('Fresh basil',10,'leaves'),('Parmesan',30,'g'),('Salt',0.5,'tsp')],
       ['Bring a large saucepan of water to a boil. Add the salt and cook the spaghetti according to its packet instructions.',
        'Halve the tomatoes and thinly slice the garlic. Warm the olive oil in a wide pan over medium heat.',
        'Add the garlic and stir for 30 seconds, without browning it. Add the tomatoes and cook for 12–15 minutes until soft.',
        'Reserve a mug of pasta water before draining. Add the spaghetti and a splash of that water to the tomato pan.',
        'Toss over gentle heat until glossy. Tear in the basil, grate over the Parmesan and serve immediately.'],
       ['Vegetarian','Weeknight','Pasta']),
recipe(2, 'Weekend berry pancakes', 'American', 10, 15, 2,
       'Fluffy little pancakes, fresh berries and a spoonful of maple syrup for a slow morning.',
       [('All-purpose flour',140,'g'),('Milk',180,'ml'),('Egg',1,''),('Baking powder',1.5,'tsp'),('Sugar',1,'tbsp'),('Butter',20,'g'),('Mixed berries',150,'g'),('Maple syrup',2,'tbsp')],
       ['Stir together the flour, baking powder and sugar. In a second bowl, whisk the milk and egg.',
        'Melt half the butter. Fold the wet ingredients and melted butter into the flour just until combined; a few small lumps are fine.',
        'Warm a nonstick pan over medium-low heat and lightly butter it. Spoon in small rounds of batter with space between them.',
        'Cook until the tops show bubbles and the edges look set, about 2 minutes. Flip and cook the second side until golden and cooked through.',
        'Repeat with the remaining batter. Serve with washed berries and maple syrup.'],
       ['Breakfast','Vegetarian','Brunch']),
recipe(3, 'Classic cheeseburger & fries', 'American', 15, 30, 2,
       'A crisp-edged beef burger with melted cheddar, pickles and oven fries.',
       [('Ground beef',300,'g'),('Burger buns',2,''),('Cheddar',40,'g'),('Potatoes',400,'g'),('Olive oil',1,'tbsp'),('Lettuce',2,'leaves'),('Tomato',1,''),('Pickles',4,'slices'),('Mustard',2,'tsp')],
       ['Heat the oven to 220°C / 425°F. Cut the potatoes into slim fries, dry well, toss with oil and spread out on a tray.',
        'Bake for 25–30 minutes, turning halfway, until browned and tender.',
        'Shape the beef into two patties without compressing it too much. Season and cook in a hot skillet, turning once.',
        'Use a food thermometer to check that the center of each beef patty reaches 71°C / 160°F. Add cheddar near the end to melt.',
        'Toast the buns. Layer with mustard, lettuce, tomato, burger and pickles. Serve promptly with the fries.'],
       ['Dinner','Comfort food']),
recipe(4, 'Margherita pizza', 'Italian', 20, 15, 2,
       'Tomato, mozzarella and basil on a golden crust. A simple pizza night made at home.',
       [('Ready-to-bake pizza dough',350,'g'),('Crushed tomatoes',150,'g'),('Mozzarella',125,'g'),('Olive oil',1,'tbsp'),('Fresh basil',8,'leaves'),('Flour for dusting',1,'tbsp')],
       ['Heat the oven to 240°C / 465°F with a sturdy baking tray inside. Follow the dough packaging if it specifies a lower temperature.',
        'Drain and tear the mozzarella. Season the crushed tomatoes with a small pinch of salt.',
        'On lightly floured baking paper, stretch the dough into a round with a slightly thicker edge.',
        'Spread a thin layer of tomato over the center and scatter the mozzarella. Transfer with the paper onto the hot tray.',
        'Bake for 12–15 minutes, until the base is cooked and the edge is golden. Finish with basil and olive oil before slicing.'],
       ['Vegetarian','Weekend','Pizza']),
recipe(5, 'Lemon herb salmon', 'European', 10, 15, 2,
       'Golden salmon with lemon, herbs and a fresh side salad. Clean flavors and very little washing up.',
       [('Salmon fillets',300,'g'),('Olive oil',1,'tbsp'),('Lemon',1,''),('Fresh parsley',2,'tbsp'),('Garlic clove',1,''),('Mixed salad leaves',100,'g')],
       ['Pat the salmon dry. Finely chop the parsley and garlic and grate a little lemon zest.',
        'Warm a nonstick skillet over medium heat with the olive oil. Place the fillets skin-side down if they have skin.',
        'Cook gently for 4–6 minutes, turn carefully, and cook until the thickest part reaches 63°C / 145°F on a food thermometer.',
        'Turn off the heat. Add the garlic, parsley, zest and a squeeze of lemon to the warm pan.',
        'Serve with washed salad leaves and extra lemon wedges. Check carefully for bones.'],
       ['Seafood','Weeknight','Gluten-free']),
recipe(6, 'Pepper steak skillet', 'French-inspired', 10, 20, 2,
       'A bistro-style steak with cracked pepper and a quick pan sauce.',
       [('Beef steaks',350,'g'),('Olive oil',1,'tbsp'),('Butter',15,'g'),('Black pepper',1,'tsp'),('Beef stock',100,'ml'),('Cream',60,'ml'),('Green beans',200,'g')],
       ['Pat the steaks dry and season with salt and cracked pepper. Heat a heavy skillet over medium-high heat.',
        'Add the oil and sear both sides. Lower the heat and continue cooking until the center reaches at least 63°C / 145°F; rest for 3 minutes.',
        'Meanwhile, boil the beans until tender. Drain and keep warm.',
        'With the steak resting, lower the pan heat and add the stock. Scrape up the browned juices, then stir in cream and butter.',
        'Simmer briefly until lightly thickened. Spoon the sauce over the rested steak and serve with beans.'],
       ['Dinner','Bistro']),
recipe(7, 'Rustic vegetable soup', 'European', 15, 30, 4,
       'A cozy pot of tomatoes, garden vegetables and beans, perfect with a slice of crusty bread.',
       [('Onion',1,''),('Carrots',2,''),('Celery stalks',2,''),('Zucchini',1,''),('Chopped tomatoes',400,'g'),('Cooked white beans',240,'g'),('Vegetable stock',900,'ml'),('Olive oil',2,'tbsp'),('Dried thyme',1,'tsp')],
       ['Wash the vegetables. Peel and dice the onion and carrots; chop the celery and zucchini into similar small pieces.',
        'Warm the oil in a large pot. Add onion, carrot and celery and cook gently for 8 minutes, stirring often.',
        'Add the zucchini, tomatoes, thyme and stock. Bring to a boil, then lower to a simmer for 20 minutes.',
        'Rinse the cooked beans and add them to the pot. Simmer for another 5 minutes until everything is piping hot.',
        'Taste, season and serve. Cool leftovers promptly and refrigerate within 2 hours.'],
       ['Vegan','One pot','Lunch']),
recipe(8, 'Market garden salad', 'European', 15, 0, 2,
       'Crunchy greens, cucumber and tomatoes with a sharp little mustard dressing.',
       [('Mixed salad leaves',120,'g'),('Cucumber',0.5,''),('Cherry tomatoes',150,'g'),('Red onion',0.25,''),('Olive oil',2,'tbsp'),('Lemon juice',1,'tbsp'),('Dijon mustard',1,'tsp'),('Crusty bread',2,'slices')],
       ['Wash the leaves and vegetables and dry them well. Tear larger leaves into bite-size pieces.',
        'Slice the cucumber, halve the tomatoes and thinly slice the onion.',
        'Whisk the oil, lemon juice and mustard with a small pinch of salt and pepper.',
        'Put the vegetables in a wide bowl. Add just enough dressing to coat and toss gently.',
        'Serve straight away with toasted bread. Keep any extra dressing chilled in a covered container.'],
       ['Vegan','Quick','Lunch']),
recipe(9, 'Sunday roast chicken', 'British', 20, 80, 4,
       'A golden roast chicken with crisp potatoes, lemon and fragrant herbs.',
       [('Whole chicken',1.4,'kg'),('Potatoes',800,'g'),('Lemon',1,''),('Garlic cloves',4,''),('Olive oil',2,'tbsp'),('Rosemary',3,'sprigs'),('Carrots',4,'')],
       ['Heat the oven to 200°C / 390°F. Keep raw chicken and its utensils separate from other ingredients; do not wash raw poultry.',
        'Scrub and cut the potatoes and carrots. Toss them with half the oil and rosemary in a roasting tray.',
        'Pat the chicken dry, rub with the remaining oil and season. Place on top of the vegetables with lemon halves and garlic around it.',
        'Roast for approximately 75–90 minutes, checking as needed. The thickest part of the breast and thigh must reach 74°C / 165°F, without touching bone.',
        'Rest for 10 minutes before carving. Check the vegetables are tender and serve with the pan juices.'],
       ['Sunday lunch','Family','Roast']),
recipe(10, 'Tomato basil bruschetta', 'Italian', 15, 5, 2,
       'Juicy chopped tomatoes on warm toasted bread, finished with basil and good olive oil.',
       [('Ripe tomatoes',300,'g'),('Sourdough bread',4,'slices'),('Garlic clove',1,''),('Olive oil',2,'tbsp'),('Fresh basil',6,'leaves'),('Balsamic vinegar',1,'tsp')],
       ['Wash and dice the tomatoes. Put them in a bowl with a pinch of salt and leave for 5 minutes.',
        'Tear the basil and fold it into the tomatoes with half the oil and the balsamic vinegar.',
        'Toast or grill the bread until golden on both sides.',
        'Cut the garlic clove in half and lightly rub the cut side across the warm bread.',
        'Spoon on the tomatoes, drizzle with the remaining oil and serve before the bread softens.'],
       ['Vegan','Starter','Quick']),
recipe(11, 'Roasted tomato mozzarella toast', 'Italian-inspired', 10, 25, 2,
       'Sweet roasted tomatoes, soft mozzarella and golden toast for a generous lunch.',
       [('Cherry tomatoes',300,'g'),('Mozzarella',125,'g'),('Sourdough bread',2,'thick slices'),('Olive oil',1,'tbsp'),('Dried oregano',0.5,'tsp'),('Fresh basil',6,'leaves')],
       ['Heat the oven to 200°C / 390°F. Toss the tomatoes with the oil and oregano in a small baking dish.',
        'Roast for about 20 minutes until softened and beginning to burst.',
        'Toast the bread. Drain and tear the mozzarella.',
        'Top the toast with warm tomatoes and mozzarella. Return to the oven for 3–5 minutes if you prefer melted cheese.',
        'Scatter over basil and serve warm, spooning a little tomato juice over each slice.'],
       ['Vegetarian','Lunch','Toast']),
recipe(12, 'Herb chicken tray bake', 'European', 15, 45, 3,
       'Chicken, potatoes and herbs roasted together in one easy tray.',
       [('Chicken thighs',600,'g'),('Small potatoes',500,'g'),('Red onion',1,''),('Carrots',3,''),('Olive oil',2,'tbsp'),('Dried oregano',1,'tsp'),('Lemon',1,'')],
       ['Heat the oven to 210°C / 410°F. Wash and halve the potatoes, cut the onion into wedges and slice the carrots.',
        'Put the vegetables in a roasting tray with the oil, oregano and lemon wedges. Toss to coat.',
        'Place the chicken on top and season. Keep raw poultry utensils separate from ready-to-eat foods.',
        'Roast for 40–50 minutes. Check the thickest part of each thigh reaches 74°C / 165°F with a food thermometer and the potatoes are tender.',
        'Rest for 5 minutes and serve with the roasted vegetables and pan juices.'],
       ['One tray','Family','Dinner'])
]

manifest = json.loads((ROOT/'Assets/SourceMedia/manifest.json').read_text())
videos=[]
for record in manifest['records']:
    if record['kind'] != 'video': continue
    index=int(record['id'].split('-')[-1])
    videos.append(dict(id=record['id'], title=record['title'], category=['Pasta','Breakfast','Vegetables','Dinner','Baking','Salads'][index-1],
        image_url=f"{ORIGIN}/{record['coverAsset']}", video_url=f"{ORIGIN}/{record['asset']}",
        payload=dict(chef=record['author'], durationSeconds=round(record['seconds']),
            summary='A sourced cooking film, presented as a replay. Filmmaker credit: '+record['author']+'. No live audience or message delivery is implied.',
            recipeID=(f'recipe-{[1,2,0,6,4,8][index-1]:02}' if index != 3 else None))))
tutorial_path = ROOT/'docs/recipe-tutorials.json'
if tutorial_path.exists():
    tutorials = {r['recipeID']:r['tutorial'] for r in json.loads(tutorial_path.read_text())}
    for item in RECIPES:
        if item['id'] in tutorials: item['payload']['tutorial'] = tutorials[item['id']]
(ROOT/'docs/catalog-recipes.json').write_text(json.dumps(RECIPES,indent=2)+'\n')
(ROOT/'docs/catalog-videos.json').write_text(json.dumps(videos,indent=2)+'\n')
print(f'Wrote {len(RECIPES)} original recipes and {len(videos)} sourced replay records.')
