---
layout: page
title: Tech
header : Technique Reports
group: navigation
---
###Here are some of my technique notes:

{% for page in site.pages %}
{% assign array = page.url | replace: '/', ' ' | split: ' '  %}
{% if array[0] == "tech" %}
{% unless array.last == "index.html" or array.last contains "++" %}
   [{{ page.title }}]({{ page.url }})
{% endunless %}
{% endif %}
{% endfor %}
