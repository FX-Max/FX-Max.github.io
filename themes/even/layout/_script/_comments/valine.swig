{%- if theme.valine.enable -%}
<!-- valine Comments -->
<script src="//github.elemecdn.com/leancloud-storage@3/dist/av-min.js"></script>
<script src="//cdn.jsdelivr.net/gh/xcss/valine@v1.5.1/dist/Valine.min.js"></script>
<script type="text/javascript">
    new Valine({
        el: '#vcomments',
        notify: {{ theme.valine.notify }},
        verify: {{ theme.valine.verify }},
        app_id: "{{ theme.valine.appid }}",
        app_key: "{{ theme.valine.appkey }}",
        placeholder: "{{ theme.valine.placeholder }}",
        avatar: '{{ theme.valine.avatar }}'
    });
</script>
{% endif %}