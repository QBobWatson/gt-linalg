<!DOCTYPE html> <!-- -*- html -*- -->
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1, maximum-scale=1">
  <title><%block name="title">Demo</%block></title>
  <link rel="shortcut icon" href="img/gatech.gif"/>

  <%block name="css">
      <link rel="stylesheet" href="${"css/demo.css" | vers}">
  </%block>

  <style>
      <%block name="inline_style"/>
  </style>

</head>
<body>
    <%block name="body_html"/>

    <%block name="js">
        <script src="${"js/demo.js" | vers}"></script>
    </%block>

    <script type="text/javascript">
        "use strict";
        DomReady.ready(function() {

        <%block name="content" filter="coffee">
            ${next.body()}
        </%block>

        });
    </script>
</body>
</html>

