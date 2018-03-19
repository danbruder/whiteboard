import './main.css';
import {Main} from './Main.elm';
import {Main as Main2} from './Main2.elm';
import registerServiceWorker from './registerServiceWorker';

import {Socket, Presence} from 'phoenix-socket';

let app = Main.embed(document.getElementById('root'), {
  //canvasWidth: window.outerWidth - 280,
  canvasWidth: parseInt(window.outerWidth / 2),
  canvasHeight: window.innerHeight,
});
let app2 = Main2.embed(document.getElementById('root2'), {
  //canvasWidth: window.outerWidth - 280,
  canvasWidth: parseInt(window.outerWidth / 2),
  canvasHeight: window.innerHeight,
});

let url = '/socket';

let presences = {};
let socket = new Socket(url);
socket.connect();

let room = socket.channel('whiteboard:lobby');
room.on('presence_state', state => {
  presences = Presence.syncState(presences, state);
  updateUsers(presences);
});

room.on('presence_diff', diff => {
  presences = Presence.syncDiff(presences, diff);
  updateUsers(presences);
});

room.on('external_draw', ({data}) => {
  app2.ports.receiveDraw.send(data);
});

const updateUsers = presences => {
  let users = [];
  Object.keys(presences).forEach((val, index) => {
    let {id, color, name} = presences[val].metas[0];
    users.push({
      id: val.toString(),
      color: color || '',
      name: name || '',
    });
  });

  app.ports.presenceUpdate.send(users);
};

room.join();

app.ports.updateColor.subscribe(function(color) {
  room.push('update_user', {color: color});
});

app.ports.updateName.subscribe(function(name) {
  room.push('update_user', {name});
});

app.ports.handleDraw.subscribe(function(data) {
  room.push('draw', data);
});

registerServiceWorker();
