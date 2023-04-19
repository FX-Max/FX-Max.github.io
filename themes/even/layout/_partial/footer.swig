{#- Social Links -#}
{%- include "./_footer/social.swig" -%}

<div class="copyright">
  <span class="power-by">
    {{ __('footer.powered', '<a class="hexo-link" href="https://hexo.io/">Hexo</a>') }}
  </span>
  <span class="division">|</span>
  <span class="theme-info">
    {{ __('footer.theme') }} - 
    <a class="theme-link" href="https://github.com/ahonn/hexo-theme-even">Even</a>
  </span>

  <span class="copyright-year">
    {%- set current = date(Date.now(), "YYYY") -%}
    &copy;
    {%- if theme.since and theme.since != current -%}
      {{ theme.since }} - {{ current }}
    {%- else -%}
      {{ current }}
    {%- endif -%} 

    <span class="heart">
      <i class="iconfont icon-heart"></i>
    </span>
    <span class="author">{{ config.author }}</span>

    {%- if theme.footer.ICP.enable -%}
      <span class="division">|</span>
      <a class="theme-link" href={{ theme.footer.ICP.url }}>{{ theme.footer.ICP.text }}</a>
    {%- endif -%} 

    {%- if theme.busuanzi.enable -%}
      <span class="division">|</span>
      <span id="busuanzi_container_site_pv">
        本站总访问量<span id="busuanzi_value_site_pv"></span>次
      </span>
    {%- endif -%} 

  </span>
</div>
