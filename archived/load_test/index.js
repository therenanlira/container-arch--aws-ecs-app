import http, { head } from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 100,
  duration: '300s',
};

const params = {
  headers: {
    'Content-Type': 'application/json',
    'Host': 'chip.linuxtips.demo',
  },
};

export default function () {
  http.get('http://linuxtips-ecscluster--alb-1158440245.us-east-1.elb.amazonaws.com/burn/cpu');
  sleep(1);
}