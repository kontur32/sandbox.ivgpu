module namespace statistic = 'statistic.root';


declare 
  %rest:path( '/sandbox/ivgpu/statistic' )
  %output:method( 'xhtml' )
function statistic:view(){
 let $body :=
  <div>
    <h2>Точки доступа сервиса статистики ООП ИВГПУ <i>simplex</i></h2>
    <ul>
      <li><a href = '/sandbox/ivgpu/statistic/oop.subjects.dep'>Статистика дисцпилн по всем кафедрам</a>
      </li>
      <li><a href = '/sandbox/ivgpu/directions'>Списоки: направления/ООП/дисциплины</a>
      </li>
      <li><a href = '/sandbox/ivgpu/subjects.Department.Direction?id=21&amp;mode=full'>Список дисцпилн по кафедре</a>
      </li>
    </ul>
    <p><a href = 'http://iro37.ru/xqwiki/TRaC/simplex'>справка по сервису</a></p>
  </div>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $body into .//body
};