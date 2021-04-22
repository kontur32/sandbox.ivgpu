module namespace statistic = 'statistic.root';

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

declare 
  %rest:path( '/sandbox/ivgpu/statistic' )
  %output:method( 'xhtml' )
function statistic:view(){
 let $authURL :=
   'https://accounts.ivgpu.com/login?redirect=' ||
   'https://sm.ivgpu.com/sandbox/ivgpu/statistic/login?redirect=https://sm.ivgpu.com/sandbox/ivgpu/statistic'
 
 let $body :=
  <div>
    <h2>Точки доступа сервиса статистики ООП ИВГПУ <i>simplex</i></h2>
    <ul>
      <li><a href = '/sandbox/ivgpu/statistic/oop.subjects.dep'>Статистика дисцпилн по всем кафедрам</a>
      </li>
      <li><a href = '/sandbox/ivgpu/directions'>Сводные списки: направления/программы/дисциплины</a>
      </li>
      <li><a href = '/sandbox/ivgpu/subjects.Department.Direction?id=21&amp;mode=full'>Список дисцпилн по кафедре</a>
      </li>
    </ul>
    <p><a href = 'http://iro37.ru/xqwiki/TRaC/simplex'>справка по сервису</a></p>
    {
      if( session:get( 'login' ) )
      then(
        <div class = 'button'><a href = 'https://sm.ivgpu.com/sandbox/ivgpu/statistic/logout' type="button" class="btn btn-primary" >выйти</a></div>
      )
      else(
        <div class = 'button'><a href = '{ $authURL }' type="button" class="btn btn-primary" >авторизоваться</a></div>
      )
    }
    {
      if( session:get( 'login' ) )
      then(
        <div>пользователь: { session:get( 'login' ) } кафедра: { session:get( 'department' ) }</div>
      )
      else()
    }
    
  </div>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $body into .//body
};