import React, { useState, useEffect, useRef } from 'react';
import { Theme, FormControl, Tooltip } from '@material-ui/core';
import {makeStyles} from '@material-ui/core/styles';
import Button from '../components/custom-button';
import RoleRadio from '../components/role-radio';
import Icon from '../components/icon';
import FormInput from '../components/form-input';
import FormSelect from '../components/form-select';
import LangSelect from '../components/lang-select';
import { isElectron } from '../utils/platform';
import { usePlatform } from '../containers/platform-container';
import {useHistory} from 'react-router-dom';
import {GithubIcon} from '../components/github-icon';
import { globalStore, roomTypes } from '../stores/global';
import { t } from '../i18n';
import GlobalStorage from '../utils/custom-storage';
import { genUUID } from '../utils/api';
import Log from '../utils/LogUploader';
import {roomStore} from "../stores/room";

const useStyles = makeStyles ((theme: Theme) => ({
    formControl: {
        minWidth: '240px',
        maxWidth: '240px',
    }
}));

type SessionInfo = {
    roomName: string
    roomType: number
    yourName: string
    role: string
}

const defaultState: SessionInfo = {
    roomName: '',
    roomType: 0,
    role: '',
    yourName: '',
}

function HomeDefaultPage(props: any) {
    document.title = t(`home.short_title.title`)

    const classes = useStyles();

    const history = useHistory();

    const handleSetting = (evt: any) => {
        history.push({pathname: `/device_test`});
    }

    const [lock, setLock] = useState<boolean>(false);

    const {
        HomeBtn
    } = usePlatform();

    const ref = useRef<boolean>(false);

    useEffect(() => {
        return () => {
            ref.current = true;
        }
    }, []);

    const [session, setSessionInfo] = useState<SessionInfo>(defaultState);

    const [required, setRequired] = useState<any>({} as any);

    const handleSubmit4Load = (roomname:String ,nickname:String,ut:String) => {
        // if (!session.roomName) {
        //     setRequired({...required, roomName: t('home.missing_room_name')});
        //     return;
        // }
        //
        // if (!session.yourName) {
        //     setRequired({...required, yourName: t('home.missing_your_name')});
        //     return;
        // }
        //
        // if (!session.role) {
        //     setRequired({...required, role: t('home.missing_role')});
        //     return;
        // }
        //
        // if (!roomTypes[session.roomType]) return;
        const path = roomTypes[0].path
        globalStore.showLoading()
        roomStore.LoginToRoom({
            userName: nickname,
            roomName: roomname,
            role: ut === 'teacher' ? 1 : 2,
            type: 0,
            uuid: genUUID()
        }).then(() => {
            // alert(`/classroom/${path}`);
            history.push(`/classroom/${path}`)
        }).catch((err: any) => {
            if (err.hasOwnProperty('api_error')) {
                return
            }
            if (err.reason) {
                globalStore.showToast({
                    type: 'rtmClient',
                    message: t('toast.rtm_login_failed_reason', {reason: err.reason}),
                })
            } else {
                globalStore.showToast({
                    type: 'rtmClient',
                    message: t('toast.rtm_login_failed'),
                })
            }
            console.warn(err)
        }).finally(() => {
            globalStore.stopLoading();
        })
    }

    useEffect(() => {
         const path = roomTypes[0].path;
        // alert(0);
         setTimeout(()=>{
             // globalStore.showLoading();
             console.log(props.match.params);
             const urlParams=props.match.params
             setSessionInfo({
                 ...session,
                 roomName: urlParams.roomname
             });

             setSessionInfo({
                 ...session,
                 yourName: urlParams.nickname
             });

             setSessionInfo({
                 ...session,
                 roomType: 0
             });

             var ut = "student"
             if(urlParams.usertype==0){
                 ut = "teacher"
             }
             setSessionInfo({
                 ...session,
                 role:ut
             });
             handleSubmit4Load(urlParams.roomname,urlParams.nickname,ut);
         },0);

    }, []);
    return (
        <div className={`flex-container ${isElectron ? 'draggable' : 'home-cover-web' }`}>
            <div className="custom-card" style={{display:"none"}}>

            </div>
        </div>
    )
}
export default React.memo(HomeDefaultPage);